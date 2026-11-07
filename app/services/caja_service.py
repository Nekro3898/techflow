from decimal import Decimal, InvalidOperation

from app.db import cursor_db


class CajaService:
    def actual(self):
        with cursor_db() as (_, cur):
            cur.execute(
                """
                SELECT *
                FROM caja
                WHERE estado = 'abierta'
                ORDER BY id DESC
                LIMIT 1
                """
            )
            return cur.fetchone()

    def abrir(self, saldo_inicial):
        try:
            saldo_inicial = Decimal(str(saldo_inicial))
        except (InvalidOperation, TypeError):
            raise ValueError("El saldo inicial no es valido.")

        if saldo_inicial < 0:
            raise ValueError("El saldo inicial no puede ser negativo.")

        with cursor_db() as (_, cur):
            cur.execute(
                "SELECT id FROM caja WHERE estado = 'abierta' LIMIT 1"
            )
            if cur.fetchone():
                raise ValueError("Ya hay una caja abierta.")

            cur.execute(
                """
                INSERT INTO caja (fecha_apertura, saldo_inicial, estado)
                VALUES (NOW(), %s, 'abierta')
                """,
                (saldo_inicial,),
            )
            caja_id = cur.lastrowid

            return caja_id

    def cerrar(self, caja_id, efectivo_contado):
        try:
            efectivo_contado = Decimal(str(efectivo_contado))
        except (InvalidOperation, TypeError):
            raise ValueError("El efectivo contado no es valido.")

        if efectivo_contado < 0:
            raise ValueError("El efectivo contado no puede ser negativo.")

        with cursor_db() as (_, cur):
            cur.execute(
                """
                SELECT *
                FROM caja
                WHERE id = %s AND estado = 'abierta'
                FOR UPDATE
                """,
                (caja_id,),
            )
            caja = cur.fetchone()

            if not caja:
                raise LookupError("Caja abierta no encontrada.")

            cur.execute(
                """
                SELECT COALESCE(
                    SUM(
                        CASE
                            WHEN tipo IN ('ingreso', 'venta') THEN importe
                            WHEN tipo = 'retiro' THEN -importe
                            ELSE 0
                        END
                    ),
                    0
                ) AS total
                FROM movimientos_caja
                WHERE caja_id = %s
                """,
                (caja_id,),
            )
            movimientos = cur.fetchone()

            saldo_inicial = Decimal(str(caja["saldo_inicial"]))
            movimiento_total = Decimal(str(movimientos["total"]))
            esperado = saldo_inicial + movimiento_total
            diferencia = efectivo_contado - esperado

            cur.execute(
                """
                UPDATE caja
                SET
                    fecha_cierre = NOW(),
                    efectivo_contado = %s,
                    efectivo_esperado = %s,
                    diferencia = %s,
                    estado = 'cerrada'
                WHERE id = %s
                """,
                (
                    efectivo_contado,
                    esperado,
                    diferencia,
                    caja_id,
                ),
            )

            return {
                "esperado": f"{esperado:.2f}",
                "contado": f"{efectivo_contado:.2f}",
                "diferencia": f"{diferencia:.2f}",
            }
