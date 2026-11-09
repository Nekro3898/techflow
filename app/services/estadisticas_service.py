from app.db import cursor_db
from app.services import rango_fechas


# Un registro por venta o posventa. Los precios historicos no se reescriben.
_MOVIMIENTOS = """
    SELECT v.fecha_hora, 1 AS ventas, v.total,
           COALESCE(d.unidades, 0) AS unidades
    FROM ventas v
    LEFT JOIN (SELECT venta_id, SUM(cantidad) AS unidades FROM detalle_venta GROUP BY venta_id) d
        ON d.venta_id = v.id
    WHERE v.estado = 'completada'
    UNION ALL
    SELECT p.fecha_hora, 0 AS ventas, p.total_diferencia AS total,
           COALESCE(SUM(CASE WHEN l.direccion = 'nuevo' THEN l.cantidad ELSE -CAST(l.cantidad AS SIGNED) END), 0) AS unidades
    FROM devoluciones p JOIN ventas v ON v.id = p.venta_id
    LEFT JOIN detalle_devolucion l ON l.devolucion_id = p.id
    WHERE v.estado = 'completada'
    GROUP BY p.id, p.fecha_hora, p.total_diferencia
"""


class EstadisticasService:
    def resumen(self, desde, hasta):
        rango_fechas(desde, hasta)
        with cursor_db() as (_, cur):
            cur.execute(f"""
                SELECT COALESCE(SUM(ventas), 0) AS ventas,
                       COALESCE(SUM(total), 0) AS total,
                       COALESCE(SUM(total) / NULLIF(SUM(ventas), 0), 0) AS promedio,
                       COALESCE(SUM(unidades), 0) AS unidades
                FROM ({_MOVIMIENTOS}) m
                WHERE fecha_hora >= CONCAT(%s, ' 00:00:00')
                  AND fecha_hora <= CONCAT(%s, ' 23:59:59')
            """, (desde, hasta))
            return cur.fetchone()

    def productos(self, desde, hasta):
        rango_fechas(desde, hasta)
        with cursor_db() as (_, cur):
            cur.execute("""
                SELECT p.nombre AS producto, SUM(m.unidades) AS unidades, SUM(m.importe) AS facturacion
                FROM (
                    SELECT d.variante_id, d.cantidad AS unidades, d.subtotal AS importe, v.fecha_hora
                    FROM detalle_venta d JOIN ventas v ON v.id = d.venta_id
                    WHERE v.estado = 'completada'
                    UNION ALL
                    SELECT l.variante_id,
                           CASE WHEN l.direccion = 'nuevo' THEN l.cantidad ELSE -CAST(l.cantidad AS SIGNED) END,
                           CASE WHEN l.direccion = 'nuevo' THEN l.cantidad * l.precio_unitario
                                ELSE -l.cantidad * l.precio_unitario END, r.fecha_hora
                    FROM detalle_devolucion l JOIN devoluciones r ON r.id = l.devolucion_id
                    JOIN ventas v ON v.id = r.venta_id WHERE v.estado = 'completada'
                ) m
                JOIN variantes va ON va.id = m.variante_id
                JOIN productos p ON p.id = va.producto_id
                WHERE m.fecha_hora >= CONCAT(%s, ' 00:00:00')
                  AND m.fecha_hora <= CONCAT(%s, ' 23:59:59')
                GROUP BY p.id, p.nombre ORDER BY unidades DESC, facturacion DESC LIMIT 20
            """, (desde, hasta))
            return cur.fetchall()

    def por_dia(self, desde, hasta):
        rango_fechas(desde, hasta)
        with cursor_db() as (_, cur):
            cur.execute(f"""
                SELECT DATE(fecha_hora) AS fecha, SUM(ventas) AS ventas, SUM(total) AS total
                FROM ({_MOVIMIENTOS}) m
                WHERE fecha_hora >= CONCAT(%s, ' 00:00:00')
                  AND fecha_hora <= CONCAT(%s, ' 23:59:59')
                GROUP BY DATE(fecha_hora) ORDER BY fecha
            """, (desde, hasta))
            return cur.fetchall()
