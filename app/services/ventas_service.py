import hashlib
import json
from decimal import Decimal, InvalidOperation

from app.db import cursor_db


class VentaError(ValueError):
    pass


class VentasService:
    MEDIOS = {"efectivo", "transferencia", "tarjeta"}

    def crear(self, data):
        if not isinstance(data, dict):
            raise VentaError("Envia un objeto JSON valido.")

        items = data.get("items") or []
        pagos = data.get("pagos") or []
        solicitud_id = str(data.get("solicitud_id", "")).strip()

        if not items:
            raise VentaError("La venta debe tener al menos un producto.")
        if not pagos:
            raise VentaError("La venta debe incluir al menos un pago.")
        if not solicitud_id:
            raise VentaError("solicitud_id es obligatorio.")

        try:
            caja_id = int(data.get("caja_id", 0))
        except (TypeError, ValueError):
            caja_id = 0

        if caja_id <= 0:
            raise VentaError("La caja es obligatoria.")

        with cursor_db() as (_, cur):
            payload = json.dumps(
                {
                    "items": items,
                    "pagos": pagos,
                    "caja_id": caja_id,
                },
                sort_keys=True,
                separators=(",", ":"),
            )
            contenido_hash = hashlib.sha256(payload.encode()).hexdigest()

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
                        "cambio": "0.00",
                        "repetida": True,
                    }

            cur.execute(
                """
                SELECT id
                FROM caja
                WHERE id = %s AND estado = 'abierta'
                """,
                (caja_id,),
            )
            if not cur.fetchone():
                raise VentaError("La caja indicada no esta abierta.")

            total = Decimal("0.00")
            lineas = []

            for item in items:
                try:
                    variante_id = int(item.get("variante_id", 0))
                    cantidad = int(item.get("cantidad", 0))
                except (TypeError, ValueError):
                    raise VentaError("Cada producto requiere una cantidad valida.")

                if variante_id <= 0 or cantidad <= 0:
                    raise VentaError("Cada producto requiere una cantidad positiva.")

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

            pagos_normalizados = []
            suma_pagos = Decimal("0.00")

            for pago in pagos:
                medio = str(pago.get("medio", "")).strip().lower()

                try:
                    importe = Decimal(str(pago.get("importe", "0")))
                except (InvalidOperation, TypeError):
                    raise VentaError("El importe de pago no es valido.")

                if medio not in self.MEDIOS or importe <= 0:
                    raise VentaError("Medio de pago o importe invalido.")

                importe = importe.quantize(Decimal("0.01"))
                suma_pagos += importe
                pagos_normalizados.append((medio, importe))

            if suma_pagos != total:
                raise VentaError(
                    f"Los pagos deben sumar exactamente ${total:.2f}."
                )

            try:
                efectivo_recibido = Decimal(
                    str(data.get("efectivo_recibido", "0") or "0")
                )
            except (InvalidOperation, TypeError):
                raise VentaError("El efectivo recibido no es valido.")

            if efectivo_recibido < 0:
                raise VentaError("El efectivo recibido no puede ser negativo.")

            efectivo_aplicado = sum(
                (
                    importe
                    for medio, importe in pagos_normalizados
                    if medio == "efectivo"
                ),
                Decimal("0.00"),
            )

            if efectivo_aplicado > 0 and efectivo_recibido < efectivo_aplicado:
                raise VentaError("El efectivo recibido no alcanza para el pago en efectivo.")

            cambio = (
                (efectivo_recibido - efectivo_aplicado).quantize(Decimal("0.01"))
                if efectivo_aplicado > 0
                else Decimal("0.00")
            )

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

    def listar(self, desde=None, hasta=None, estado=None):
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
        motivo = str(motivo or "").strip()
        if not motivo:
            raise VentaError("El motivo es obligatorio.")

        with cursor_db() as (_, cur):
            cur.execute(
                "SELECT * FROM ventas WHERE id = %s FOR UPDATE",
                (venta_id,),
            )
            venta = cur.fetchone()

            if not venta:
                raise LookupError("Venta no encontrada.")

            if venta["estado"] == "anulada":
                raise VentaError("La venta ya esta anulada.")

            cur.execute(
                "SELECT variante_id, cantidad FROM detalle_venta WHERE venta_id = %s",
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

            cur.execute(
                """
                UPDATE movimientos_caja
                SET importe = 0
                WHERE referencia = %s
                """,
                (f"Venta #{venta_id}",),
            )

            return True
