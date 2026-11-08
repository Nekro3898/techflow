import hashlib
import json
from decimal import Decimal

from app.db import cursor_db
from app.services import objeto, texto, entero, dinero, rango_fechas, NoEncontrado


class VentaError(ValueError):
    pass


class VentasService:
    MEDIOS = {"efectivo", "transferencia", "tarjeta"}

    def crear(self, data):
        data = objeto(data)
        items = data.get("items")
        pagos = data.get("pagos")
        solicitud_id = texto(data.get("solicitud_id"), "solicitud_id", 80)
        caja_id = entero(data.get("caja_id"), "Caja")
        if not isinstance(items, list) or not 1 <= len(items) <= 200:
            raise VentaError("La venta requiere entre 1 y 200 items.")
        if not isinstance(pagos, list) or not 1 <= len(pagos) <= 20:
            raise VentaError("La venta requiere entre 1 y 20 pagos.")
        agrupados = {}
        for item in items:
            objeto(item)
            vid = entero(item.get("variante_id"), "Variante")
            cantidad = entero(item.get("cantidad"), "Cantidad")
            agrupados[vid] = entero(agrupados.get(vid, 0) + cantidad, "Cantidad total")
        items = [{"variante_id": vid, "cantidad": qty} for vid, qty in sorted(agrupados.items())]
        pagos_normalizados = []
        for pago in pagos:
            objeto(pago)
            medio = texto(pago.get("medio"), "Medio de pago", 30).lower()
            if medio not in self.MEDIOS:
                raise VentaError("Medio de pago invalido.")
            pagos_normalizados.append((medio, dinero(pago.get("importe"), "Importe", Decimal("0.01"))))
        suma_pagos = dinero(sum((importe for _, importe in pagos_normalizados), Decimal(0)), "Total pagado")
        efectivo_recibido = dinero(data.get("efectivo_recibido", 0), "Efectivo recibido")
        efectivo_aplicado = sum((importe for medio, importe in pagos_normalizados if medio == "efectivo"), Decimal(0))
        if efectivo_recibido < efectivo_aplicado:
            raise VentaError("El efectivo recibido no alcanza para el pago en efectivo.")
        cambio = efectivo_recibido - efectivo_aplicado if efectivo_aplicado else Decimal(0)
        payload = json.dumps({
            "items": items,
            "pagos": [{"medio": medio, "importe": f"{importe:.2f}"} for medio, importe in pagos_normalizados],
            "caja_id": caja_id, "efectivo_recibido": f"{efectivo_recibido:.2f}",
        }, sort_keys=True, separators=(",", ":"))
        contenido_hash = hashlib.sha256(payload.encode()).hexdigest()

        with cursor_db(escritura=True) as (_, cur):
            cur.execute(
                """
                SELECT solicitud_id, contenido_hash
                FROM solicitudes_venta
                WHERE solicitud_id = %s
                FOR UPDATE
                """,
                (solicitud_id,),
            )
            solicitud = cur.fetchone()

            if solicitud:
                if solicitud["contenido_hash"] != contenido_hash:
                    raise VentaError(
                        "El identificador de solicitud ya fue usado con otros datos."
                    )

                cur.execute(
                    "SELECT id, total FROM ventas WHERE solicitud_id = %s",
                    (solicitud_id,),
                )
                venta_existente = cur.fetchone()

                if venta_existente:
                    return {
                        "id": venta_existente["id"],
                        "total": f'{Decimal(venta_existente["total"]):.2f}',
                        "cambio": f"{cambio:.2f}",
                        "repetida": True,
                    }

            cur.execute(
                """
                SELECT id
                FROM caja
                WHERE id = %s AND estado = 'abierta'
                FOR UPDATE
                """,
                (caja_id,),
            )
            if not cur.fetchone():
                raise VentaError("La caja indicada no esta abierta.")

            total = Decimal("0.00")
            lineas = []

            for item in items:
                variante_id = item["variante_id"]
                cantidad = item["cantidad"]

                cur.execute(
                    """
                    SELECT
                        v.id,
                        v.stock_actual,
                        p.precio
                    FROM variantes v
                    JOIN productos p ON p.id = v.producto_id
                    WHERE v.id = %s AND p.activo = TRUE
                    FOR UPDATE
                    """,
                    (variante_id,),
                )
                variante = cur.fetchone()

                if not variante:
                    raise VentaError(
                        f"La variante {variante_id} no existe o esta inactiva."
                    )

                if int(variante["stock_actual"]) < cantidad:
                    raise VentaError(
                        f"Stock insuficiente para la variante {variante_id}."
                    )

                precio = Decimal(str(variante["precio"])).quantize(Decimal("0.01"))
                subtotal = (precio * cantidad).quantize(Decimal("0.01"))
                total += subtotal
                lineas.append((variante_id, cantidad, precio, subtotal))

            total = dinero(total, "Total de venta", Decimal("0.01"))
            if suma_pagos != total:
                raise VentaError(f"Los pagos deben sumar exactamente ${total:.2f}.")

            medio_principal = (
                pagos_normalizados[0][0]
                if len(pagos_normalizados) == 1
                else "mixto"
            )

            cur.execute(
                """
                INSERT INTO ventas (
                    fecha_hora,
                    total,
                    medio_pago,
                    caja_id,
                    solicitud_id
                )
                VALUES (NOW(), %s, %s, %s, %s)
                """,
                (total, medio_principal, caja_id, solicitud_id),
            )
            venta_id = cur.lastrowid

            for variante_id, cantidad, precio, subtotal in lineas:
                cur.execute(
                    """
                    INSERT INTO detalle_venta (
                        venta_id,
                        variante_id,
                        cantidad,
                        precio_unitario,
                        subtotal
                    )
                    VALUES (%s, %s, %s, %s, %s)
                    """,
                    (venta_id, variante_id, cantidad, precio, subtotal),
                )

                cur.execute(
                    """
                    UPDATE variantes
                    SET stock_actual = stock_actual - %s
                    WHERE id = %s
                    """,
                    (cantidad, variante_id),
                )

                cur.execute(
                    """
                    INSERT INTO movimientos_stock (
                        variante_id,
                        tipo,
                        cantidad,
                        motivo,
                        venta_id
                    )
                    VALUES (%s, 'egreso', %s, %s, %s)
                    """,
                    (
                        variante_id,
                        cantidad,
                        f"Venta #{venta_id}",
                        venta_id,
                    ),
                )

            for medio, importe in pagos_normalizados:
                cur.execute(
                    """
                    INSERT INTO pagos_venta (venta_id, medio, importe)
                    VALUES (%s, %s, %s)
                    """,
                    (venta_id, medio, importe),
                )

            cur.execute(
                """
                INSERT INTO movimientos_caja (
                    caja_id,
                    tipo,
                    importe,
                    referencia
                )
                VALUES (%s, 'venta', %s, %s)
                """,
                (caja_id, efectivo_aplicado, f"Venta #{venta_id}"),
            )

            cur.execute(
                """
                INSERT INTO solicitudes_venta (
                    solicitud_id,
                    contenido_hash,
                    estado
                )
                VALUES (%s, %s, 'creada')
                """,
                (solicitud_id, contenido_hash),
            )

            return {
                "id": venta_id,
                "total": f"{total:.2f}",
                "cambio": f"{cambio:.2f}",
                "repetida": False,
            }

    def listar(self, desde=None, hasta=None, estado=None, limite=None):
        rango_fechas(desde, hasta)
        if estado is not None and estado not in {"completada", "anulada"}:
            raise VentaError("Estado de venta invalido.")
        sql = """
            SELECT
                id,
                fecha_hora,
                total,
                medio_pago,
                estado,
                caja_id
            FROM ventas
            WHERE 1 = 1
        """
        args = []

        if desde:
            sql += ' AND fecha_hora >= CONCAT(%s, " 00:00:00")'
            args.append(desde)

        if hasta:
            sql += ' AND fecha_hora <= CONCAT(%s, " 23:59:59")'
            args.append(hasta)

        if estado:
            sql += " AND estado = %s"
            args.append(estado)

        sql += " ORDER BY fecha_hora DESC, id DESC"
        if limite is not None:
            sql += " LIMIT %s"
            args.append(entero(limite, "Limite", 1, 1000))

        with cursor_db() as (_, cur):
            cur.execute(sql, args)
            return cur.fetchall()

    def detalle(self, venta_id):
        with cursor_db() as (_, cur):
            cur.execute(
                """
                SELECT
                    v.id,
                    v.fecha_hora,
                    v.total,
                    v.medio_pago,
                    v.estado,
                    v.motivo_anulacion,
                    v.caja_id
                FROM ventas v
                WHERE v.id = %s
                """,
                (venta_id,),
            )
            venta = cur.fetchone()

            if not venta:
                return None

            cur.execute(
                """
                SELECT
                    d.variante_id,
                    d.cantidad,
                    d.precio_unitario,
                    d.subtotal,
                    p.nombre AS producto,
                    t.nombre AS talle,
                    c.nombre AS color
                FROM detalle_venta d
                JOIN variantes va ON va.id = d.variante_id
                JOIN productos p ON p.id = va.producto_id
                JOIN talles t ON t.id = va.talle_id
                JOIN colores c ON c.id = va.color_id
                WHERE d.venta_id = %s
                ORDER BY d.id
                """,
                (venta_id,),
            )
            venta["items"] = cur.fetchall()

            cur.execute(
                """
                SELECT medio, importe
                FROM pagos_venta
                WHERE venta_id = %s
                ORDER BY id
                """,
                (venta_id,),
            )
            venta["pagos"] = cur.fetchall()

            return venta

    def anular(self, venta_id, motivo):
        motivo = texto(motivo, "Motivo", 255)

        with cursor_db(escritura=True) as (_, cur):
            cur.execute(
                "SELECT * FROM ventas WHERE id = %s FOR UPDATE",
                (venta_id,),
            )
            venta = cur.fetchone()

            if not venta:
                raise NoEncontrado("Venta no encontrada.")

            if venta["estado"] == "anulada":
                raise VentaError("La venta ya esta anulada.")

            cur.execute("SELECT estado FROM caja WHERE id = %s FOR UPDATE", (venta["caja_id"],))
            caja = cur.fetchone()
            if not caja or caja["estado"] != "abierta":
                raise VentaError("No se puede anular una venta de una caja cerrada.")

            cur.execute(
                "SELECT variante_id, cantidad FROM detalle_venta WHERE venta_id = %s ORDER BY variante_id",
                (venta_id,),
            )
            items = cur.fetchall()

            for item in items:
                cur.execute(
                    """
                    UPDATE variantes
                    SET stock_actual = stock_actual + %s
                    WHERE id = %s
                    """,
                    (item["cantidad"], item["variante_id"]),
                )
                cur.execute(
                    """
                    INSERT INTO movimientos_stock (
                        variante_id,
                        tipo,
                        cantidad,
                        motivo,
                        venta_id
                    )
                    VALUES (%s, 'devolucion', %s, %s, %s)
                    """,
                    (
                        item["variante_id"],
                        item["cantidad"],
                        motivo,
                        venta_id,
                    ),
                )

            cur.execute(
                """
                UPDATE ventas
                SET estado = 'anulada', motivo_anulacion = %s
                WHERE id = %s
                """,
                (motivo, venta_id),
            )

            cur.execute("SELECT COALESCE(SUM(importe), 0) AS efectivo FROM pagos_venta WHERE venta_id = %s AND medio = 'efectivo'", (venta_id,))
            efectivo = cur.fetchone()["efectivo"]
            if efectivo:
                cur.execute("""INSERT INTO movimientos_caja (caja_id, tipo, importe, referencia)
                               VALUES (%s, 'retiro', %s, %s)""",
                            (venta["caja_id"], efectivo, f"Anulacion venta #{venta_id}"))

            return True
