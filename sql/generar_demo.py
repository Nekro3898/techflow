"""Genera techflow_demo.sql sin conectarse ni modificar bases existentes."""
from datetime import date, datetime, time, timedelta
from decimal import Decimal
from pathlib import Path
import hashlib
import json
import random

ROOT = Path(__file__).resolve().parent
END = date(2026, 11, 7)
START = END - timedelta(days=13)
rng = random.Random(3898)
schema = (ROOT / 'techflow.sql').read_text(encoding='utf-8')
ddl = schema[schema.index('CREATE TABLE categorias'):schema.index('INSERT INTO categorias')]
lines = [
    '-- Datos ficticios: 25/10/2026 al 07/11/2026. No modifica techflow.',
    '-- Ejecutar una sola vez. Si techflow_demo existe, detener la importacion.',
    'CREATE DATABASE techflow_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;',
    'USE techflow_demo;', ddl, 'START TRANSACTION;'
]

def literal(value):
    if value is None:
        return 'NULL'
    if isinstance(value, (int, Decimal)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"

def insert(table, **values):
    lines.append(f"INSERT INTO {table} ({', '.join(values)}) VALUES ({', '.join(map(literal, values.values()))});")

created = datetime.combine(START, time(8))
for i, name in enumerate(['Remeras', 'Pantalones', 'Abrigos', 'Camisas'], 1):
    insert('categorias', id=i, nombre=name)
for i, name in enumerate(['Textiles del Litoral', 'Denim Centro', 'Moda Coronda'], 1):
    insert('proveedores', id=i, nombre=name, telefono=f'0342-555-010{i}',
           email=f'proveedor{i}@example.com', direccion=f'Calle de ejemplo {100*i}', creado_en=created)
for i, name in enumerate(['S', 'M', 'L', 'XL'], 1):
    insert('talles', id=i, nombre=name)
for i, name in enumerate(['Negro', 'Blanco', 'Azul'], 1):
    insert('colores', id=i, nombre=name)
products = [
    ('Remera basica', 1, 15000), ('Remera estampada', 1, 18500),
    ('Remera oversize', 1, 22000), ('Jean recto', 2, 32000),
    ('Jean elastizado', 2, 36000), ('Pantalon cargo', 2, 42000),
    ('Buzo liviano', 3, 28000), ('Buzo con capucha', 3, 38500),
    ('Campera de jean', 3, 65000), ('Camisa de lino', 4, 34000),
    ('Camisa a cuadros', 4, 29500), ('Camisa clasica', 4, 31000),
]
stocks, prices = {}, {}
for pid, (name, category, price) in enumerate(products, 1):
    insert('productos', id=pid, nombre=name, descripcion='Producto ficticio para demostracion',
           categoria_id=category, proveedor_id=(pid-1)%3+1, precio=price,
           activo=1, creado_en=created, actualizado_en=created)
    for size in range(1, 5):
        vid = (pid-1)*4+size
        stocks[vid] = 12
        prices[vid] = price
        insert('variantes', id=vid, producto_id=pid, talle_id=size,
               color_id=(size-1)%3+1, codigo=f'DEMO-{pid:02}-{size}',
               stock_actual=0, stock_minimo=3, creado_en=created)
        insert('movimientos_stock', variante_id=vid, tipo='ingreso', cantidad=12,
               fecha_hora=created, motivo='Recepcion inicial de mercaderia demo')

sale_id = 0
for day in range(14):
    current = START + timedelta(days=day)
    cid = day+1
    opening = datetime.combine(current, time(9))
    insert('caja', id=cid, fecha_apertura=opening, saldo_inicial=20000, estado='abierta')
    cash = Decimal(20000)
    if day in (5, 10):
        for vid in (1, 2, 5, 9):
            stocks[vid] += 6
            insert('movimientos_stock', variante_id=vid, tipo='ingreso', cantidad=6,
                   fecha_hora=opening, motivo='Reposicion de proveedor demo')
    for n in range(8 + day%4):
        sale_id += 1
        stamp = opening + timedelta(minutes=30 + n*45)
        candidates = [vid for vid, stock in stocks.items() if stock >= 2]
        # Las variantes mas populares concentran ventas y llegan a stock bajo.
        hot = [vid for vid in range(1, 13) if vid in candidates]
        selected = rng.sample(hot if hot and n%2 == 0 else candidates,
                              min(1+n%3, len(hot if hot and n%2 == 0 else candidates)))
        items = [{'variante_id': vid, 'cantidad': rng.randint(1, 2)} for vid in selected]
        total = sum(prices[x['variante_id']]*x['cantidad'] for x in items)
        medium = ['efectivo', 'transferencia', 'tarjeta', 'mixto'][n%4]
        payments = ([('efectivo', total//2), ('tarjeta', total-total//2)]
                    if medium == 'mixto' else [(medium, total)])
        canceled = day in (2, 6, 10) and n == 2
        key = f'demo-{current:%Y%m%d}-{n+1:03}'
        payload = {'items': sorted(items, key=lambda item: item['variante_id']), 'pagos': [{'medio': m, 'importe': f'{p:.2f}'} for m,p in payments], 'caja_id': cid, 'efectivo_recibido': f"{sum(p for m,p in payments if m == 'efectivo'):.2f}"}
        digest = hashlib.sha256(json.dumps(payload, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
        insert('ventas', id=sale_id, fecha_hora=stamp, total=total, medio_pago=medium,
               estado='anulada' if canceled else 'completada',
               motivo_anulacion='Cliente cancelo la compra' if canceled else None,
               caja_id=cid, solicitud_id=key)
        insert('solicitudes_venta', solicitud_id=key, contenido_hash=digest, estado='creada', creado_en=stamp)
        for item in items:
            vid, qty = item['variante_id'], item['cantidad']
            insert('detalle_venta', venta_id=sale_id, variante_id=vid, cantidad=qty,
                   precio_unitario=prices[vid], subtotal=prices[vid]*qty)
            insert('movimientos_stock', variante_id=vid, tipo='egreso', cantidad=qty,
                   fecha_hora=stamp, motivo=f'Venta #{sale_id}', venta_id=sale_id)
            stocks[vid] -= qty
            if canceled:
                stocks[vid] += qty
                insert('movimientos_stock', variante_id=vid, tipo='devolucion', cantidad=qty,
                       fecha_hora=stamp+timedelta(minutes=15), motivo='Cliente cancelo la compra', venta_id=sale_id)
        for medium_payment, amount in payments:
            insert('pagos_venta', venta_id=sale_id, medio=medium_payment, importe=amount)
        applied = sum(amount for m, amount in payments if m == 'efectivo')
        cash += applied
        insert('movimientos_caja', caja_id=cid, tipo='venta', importe=applied,
               fecha_hora=stamp, referencia=f'Venta #{sale_id}')
        if canceled and applied:
            cash -= applied
            insert('movimientos_caja', caja_id=cid, tipo='retiro', importe=applied,
                   fecha_hora=stamp+timedelta(minutes=15), referencia=f'Anulacion venta #{sale_id}')
    if day < 13:
        withdrawal = max(0, cash-30000)
        if withdrawal:
            insert('movimientos_caja', caja_id=cid, tipo='retiro', importe=withdrawal,
                   fecha_hora=datetime.combine(current, time(19)), referencia='Retiro al cierre demo')
            cash -= withdrawal
        difference = Decimal(-500 if day == 4 else 200 if day == 9 else 0)
        lines.append(f"UPDATE caja SET estado='cerrada', fecha_cierre='{current} 20:00:00', efectivo_esperado={cash}, efectivo_contado={cash+difference}, diferencia={difference} WHERE id={cid};")

for vid, stock in stocks.items():
    lines.append(f'UPDATE variantes SET stock_actual={stock} WHERE id={vid};')
lines += ['COMMIT;']
target = ROOT / 'techflow_demo.sql'
target.write_text('\n'.join(lines)+'\n', encoding='utf-8')
print(f'{target}: {sale_id} ventas, 14 cajas, 48 variantes; stock bajo: {sum(v <= 3 for v in stocks.values())}')
