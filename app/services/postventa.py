from decimal import Decimal
from app.db import cursor_db
from app.services import objeto, texto, entero, dinero, NoEncontrado
from app.services.inventario import InventarioService


class PostventaError(ValueError):
    pass


class PostventaService:
    TIPOS_OPERACION = {"cambio", "devolucion"}

    def __init__(self):
        self.inventario_service = InventarioService()

    def registrar_operacion(self, data):
        data = objeto(data)
        venta_id = entero(data.get("venta_id"), "Venta ID")
        tipo = texto(data.get("tipo"), "Tipo de operación", 30).lower()
        motivo = texto(data.get("motivo"), "Motivo", 255)
        
        if tipo not in self.TIPOS_OPERACION:
            raise PostventaError("Tipo de operación inválido. Debe ser 'cambio' o 'devolucion'.")

        items_devueltos = data.get("items_devueltos", [])
        items_nuevos = data.get("items_nuevos", [])
        diferencia_pago = dinero(data.get("diferencia_pago", 0), "Diferencia de pago", Decimal("0.01"))
        caja_id = entero(data.get("caja_id"), "Caja ID")

        if not isinstance(items_devueltos, list) or len(items_devueltos) == 0:
            raise PostventaError("Debe incluir al menos un ítem devuelto por el cliente.")

        if tipo == "cambio" and (not isinstance(items_nuevos, list) or len(items_nuevos) == 0):
            raise PostventaError("Un cambio requiere especificar los nuevos ítems que se lleva el cliente.")

        with cursor_db(escritura=True) as (_, cur):
            cur.execute(
                "SELECT * FROM ventas WHERE id = %s FOR UPDATE",
                (venta_id,)
            )
            venta = cur.fetchone()
            if not venta:
                raise NoEncontrado("La venta original no fue encontrada.")
            
            if venta["estado"] == "anulada":
                raise PostventaError("No se puede operar sobre una venta que ya está anulada.")

            cur.execute("SELECT estado FROM caja WHERE id = %s FOR UPDATE", (caja_id,))
            caja = cur.fetchone()
            if not caja or caja["estado"] != "abierta":
                raise PostventaError("La caja indicada no está abierta.")

            cur.execute(
                """
                INSERT INTO devoluciones (venta_id, motivo, tipo, total_diferencia)
                VALUES (%s, %s, %s, %s)
                """,
                (venta_id, motivo, tipo, diferencia_pago)
            )
            devolucion_id = cur.lastrowid

            for item in items_devueltos:
                objeto(item)
                variante_id = entero(item.get("variante_id"), "Variante")
                cantidad = entero(item.get("cantidad"), "Cantidad")

                self.inventario_service.movimiento(
                    variante_id=variante_id,
                    tipo="devolucion",
                    cantidad=cantidad,
                    motivo=f"Posventa #{devolucion_id} (Devolución venta #{venta_id})"
                )

            if tipo == "cambio":
                for item in items_nuevos:
                    objeto(item)
                    variante_id = entero(item.get("variante_id"), "Variante")
                    cantidad = entero(item.get("cantidad"), "Cantidad")

                    self.inventario_service.movimiento(
                        variante_id=variante_id,
                        tipo="egreso",
                        cantidad=cantidad,
                        motivo=f"Posventa #{devolucion_id} (Cambio venta #{venta_id})"
                    )

            if diferencia_pago != Decimal("0.00"):
                tipo_movimiento = "ingreso" if diferencia_pago > 0 else "retiro"
                importe_abs = abs(diferencia_pago)
                
                cur.execute(
                    """
                    INSERT INTO movimientos_caja (caja_id, tipo, importe, referencia)
                    VALUES (%s, %s, %s, %s)
                    """,
                    (caja_id, tipo_movimiento, importe_abs, f"Posventa #{devolucion_id} ({tipo})")
                )

            return {
                "devolucion_id": devolucion_id,
                "venta_id": venta_id,
                "tipo": tipo,
                "diferencia_pago": f"{diferencia_pago:.2f}",
                "mensaje": "Operación de posventa registrada exitosamente."
            }