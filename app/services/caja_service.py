from decimal import Decimal

from app.db import cursor_db
from app.services import dinero, NoEncontrado


class CajaService:
    def actual(self):
        with cursor_db() as (_, cur):
            cur.execute(
                """
                SELECT c.*,
                    c.saldo_inicial + COALESCE((
                        SELECT SUM(CASE WHEN m.tipo = 'retiro' THEN -m.importe ELSE m.importe END)
                        FROM movimientos_caja m WHERE m.caja_id = c.id
                    ), 0) AS saldo_actual
                FROM caja c
                WHERE c.estado = 'abierta'
                ORDER BY c.id DESC
                LIMIT 1
                """
            )
            return cur.fetchone()

    def abrir(self, saldo_inicial):
        saldo_inicial = dinero(saldo_inicial, "Saldo inicial")

        with cursor_db(escritura=True) as (_, cur):
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
        efectivo_contado = dinero(efectivo_contado, "Efectivo contado")

        with cursor_db(escritura=True) as (_, cur):
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
                raise NoEncontrado("Caja abierta no encontrada.")

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
