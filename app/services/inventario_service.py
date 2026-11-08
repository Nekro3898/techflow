from app.db import cursor_db
from app.services import entero, texto, NoEncontrado


class InventarioService:
    def listar(self, query="", solo_bajo=False):
        sql = """
            SELECT
                v.id,
                v.codigo,
                v.stock_actual,
                v.stock_minimo,
                p.id AS producto_id,
                p.nombre AS producto,
                p.precio,
                t.nombre AS talle,
                c.nombre AS color
            FROM variantes v
            JOIN productos p ON p.id = v.producto_id
            JOIN talles t ON t.id = v.talle_id
            JOIN colores c ON c.id = v.color_id
            WHERE p.activo = TRUE
              AND (
                    p.nombre LIKE %s
                    OR v.codigo LIKE %s
                    OR c.nombre LIKE %s
                    OR t.nombre LIKE %s
              )
        """
        args = [f"%{query}%"] * 4

        if solo_bajo:
            sql += " AND v.stock_actual <= v.stock_minimo"

        sql += " ORDER BY p.nombre, t.nombre, c.nombre"

        with cursor_db() as (_, cur):
            cur.execute(sql, args)
            return cur.fetchall()

    def movimiento(
        self,
        variante_id,
        tipo,
        cantidad,
        motivo,
        diferencia=False,
    ):
        variante_id = entero(variante_id, "Variante")
        cantidad = entero(cantidad, "Cantidad", 0 if tipo == "ajuste" else 1)
        motivo = texto(motivo, "Motivo", 180)

        with cursor_db(escritura=True) as (_, cur):
            cur.execute(
                "SELECT stock_actual FROM variantes WHERE id = %s FOR UPDATE",
                (variante_id,),
            )
            row = cur.fetchone()

            if not row:
                raise NoEncontrado("Variante no encontrada.")

            actual = int(row["stock_actual"])

            if tipo == "ajuste":
                if cantidad < 0:
                    raise ValueError("El stock final no puede ser negativo.")

                delta = cantidad - actual
                if delta == 0:
                    raise ValueError("El ajuste no cambia el stock.")

                nuevo = cantidad
                movimiento_tipo = "ingreso" if delta > 0 else "egreso"
                motivo = f"Ajuste de {actual} a {nuevo}: {motivo}"
                movimiento_cantidad = abs(delta)
            else:
                if cantidad <= 0:
                    raise ValueError("La cantidad debe ser mayor que cero.")

                if tipo not in {"ingreso", "egreso", "devolucion"}:
                    raise ValueError("Tipo de movimiento invalido.")

                delta = cantidad if tipo in {"ingreso", "devolucion"} else -cantidad
                nuevo = actual + delta
                movimiento_tipo = tipo
                movimiento_cantidad = cantidad

            if nuevo > 2147483647:
                raise ValueError("El stock supera el limite permitido.")

            if nuevo < 0:
                raise ValueError("No hay stock suficiente.")

            cur.execute(
                "UPDATE variantes SET stock_actual = %s WHERE id = %s",
                (nuevo, variante_id),
            )

            cur.execute(
                """
                INSERT INTO movimientos_stock (
                    variante_id,
                    tipo,
                    cantidad,
                    motivo
                )
                VALUES (%s, %s, %s, %s)
                """,
                (
                    variante_id,
                    movimiento_tipo,
                    movimiento_cantidad,
                    motivo,
                ),
            )

            return nuevo
