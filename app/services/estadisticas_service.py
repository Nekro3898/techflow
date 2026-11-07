from app.db import cursor_db


class EstadisticasService:
    def resumen(self, desde, hasta):
        with cursor_db() as (_, cur):
            cur.execute(
                """
                SELECT
                    COUNT(*) AS ventas,
                    COALESCE(SUM(total), 0) AS total,
                    COALESCE(AVG(total), 0) AS promedio
                FROM ventas
                WHERE estado = 'completada'
                  AND fecha_hora >= CONCAT(%s, ' 00:00:00')
                  AND fecha_hora <= CONCAT(%s, ' 23:59:59')
                """,
                (desde, hasta),
            )
            return cur.fetchone()

    def productos(self, desde, hasta):
        with cursor_db() as (_, cur):
            cur.execute(
                """
                SELECT
                    p.nombre AS producto,
                    SUM(d.cantidad) AS unidades,
                    SUM(d.subtotal) AS facturacion
                FROM detalle_venta d
                JOIN ventas v ON v.id = d.venta_id
                JOIN variantes va ON va.id = d.variante_id
                JOIN productos p ON p.id = va.producto_id
                WHERE v.estado = 'completada'
                  AND v.fecha_hora >= CONCAT(%s, ' 00:00:00')
                  AND v.fecha_hora <= CONCAT(%s, ' 23:59:59')
                GROUP BY p.id, p.nombre
                ORDER BY unidades DESC, facturacion DESC
                LIMIT 20
                """,
                (desde, hasta),
            )
            return cur.fetchall()

    def por_dia(self, desde, hasta):
        with cursor_db() as (_, cur):
            cur.execute(
                """
                SELECT
                    DATE(fecha_hora) AS fecha,
                    COUNT(*) AS ventas,
                    SUM(total) AS total
                FROM ventas
                WHERE estado = 'completada'
                  AND fecha_hora >= CONCAT(%s, ' 00:00:00')
                  AND fecha_hora <= CONCAT(%s, ' 23:59:59')
                GROUP BY DATE(fecha_hora)
                ORDER BY fecha
                """,
                (desde, hasta),
            )
            return cur.fetchall()
