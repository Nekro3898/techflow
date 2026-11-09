from decimal import Decimal, InvalidOperation
import hashlib
import json

from app.db import cursor_db
from app.services import objeto, texto, entero, dinero, NoEncontrado
from app.services.inventario_service import InventarioService


class PostventaError(ValueError):
    pass


class PostventaService:
    TIPOS_OPERACION = {'cambio', 'devolucion'}

    def __init__(self):
        self.inventario_service = InventarioService()

    def registrar_operacion(self, data):
        data = objeto(data)
        venta_id = entero(data.get('venta_id'), 'Venta ID')
        caja_id = entero(data.get('caja_id'), 'Caja ID')
        solicitud_id = texto(data.get('solicitud_id'), 'solicitud_id', 80)
        tipo = texto(data.get('tipo'), 'Tipo de operacion', 30).lower()
        motivo = texto(data.get('motivo'), 'Motivo', 255)
        medio = texto(data.get('medio_pago', 'efectivo'), 'Medio de pago', 30).lower()
        if tipo not in self.TIPOS_OPERACION:
            raise PostventaError('Tipo de operacion invalido.')
        if medio not in {'efectivo', 'tarjeta', 'transferencia'}:
            raise PostventaError('Medio de pago invalido.')

        def normalizar(items, obligatorio):
            if not isinstance(items, list) or len(items) > 200 or (obligatorio and not items):
                raise PostventaError('Los items deben ser listas de hasta 200 elementos; incluye los obligatorios.')
            cantidades = {}
            for item in items:
                objeto(item)
                vid = entero(item.get('variante_id'), 'Variante')
                cantidad = entero(item.get('cantidad'), 'Cantidad')
                cantidades[vid] = entero(cantidades.get(vid, 0) + cantidad, 'Cantidad total')
            return dict(sorted(cantidades.items()))

        devueltos = normalizar(data.get('items_devueltos', []), True)
        nuevos = normalizar(data.get('items_nuevos', []), tipo == 'cambio')
        if tipo == 'devolucion' and nuevos:
            raise PostventaError('Una devolucion no puede incluir productos nuevos.')
        esperada = None
        if 'diferencia_pago' in data:
            try:
                value = data['diferencia_pago']
                if isinstance(value, bool) or not isinstance(value, (str, int, float, Decimal)):
                    raise ValueError()
                number = Decimal(str(value))
                if not number.is_finite():
                    raise ValueError()
                esperada = dinero(abs(number), 'Diferencia de pago') * (-1 if number < 0 else 1)
            except (InvalidOperation, ValueError):
                raise PostventaError('Diferencia de pago invalida.') from None
        payload = {'venta_id': venta_id, 'caja_id': caja_id, 'tipo': tipo, 'motivo': motivo,
                   'devueltos': devueltos, 'nuevos': nuevos, 'medio': medio,
                   'esperada': str(esperada) if esperada is not None else None}
        digest = hashlib.sha256(json.dumps(payload, sort_keys=True, separators=(',', ':')).encode()).hexdigest()

        with cursor_db(escritura=True) as (_, cur):
            cur.execute('''SELECT s.contenido_hash, d.id, d.venta_id, d.tipo, d.total_diferencia
                           FROM solicitudes_postventa s JOIN devoluciones d ON d.id = s.devolucion_id
                           WHERE s.solicitud_id = %s''', (solicitud_id,))
            anterior = cur.fetchone()
            if anterior:
                if anterior['contenido_hash'] != digest:
                    raise PostventaError('solicitud_id ya fue usado con otros datos.')
                return {'devolucion_id': anterior['id'], 'venta_id': anterior['venta_id'],
                        'tipo': anterior['tipo'], 'diferencia_pago': f"{anterior['total_diferencia']:.2f}",
                        'repetida': True, 'mensaje': 'Operacion ya registrada.'}

            cur.execute('SELECT * FROM ventas WHERE id = %s FOR UPDATE', (venta_id,))
            venta = cur.fetchone()
            if not venta:
                raise NoEncontrado('La venta original no fue encontrada.')
            if venta['estado'] != 'completada':
                raise PostventaError('No se puede operar sobre una venta anulada.')
            cur.execute('SELECT * FROM caja WHERE id = %s FOR UPDATE', (caja_id,))
            caja = cur.fetchone()
            if not caja or caja['estado'] != 'abierta':
                raise PostventaError('La caja indicada no esta abierta.')
            # No inventar cantidades para operaciones antiguas sin detalle.
            cur.execute('''SELECT d.id FROM devoluciones d
                           WHERE d.venta_id = %s AND NOT EXISTS
                           (SELECT 1 FROM detalle_devolucion l WHERE l.devolucion_id = d.id) LIMIT 1''', (venta_id,))
            if cur.fetchone():
                raise PostventaError('Esta venta tiene una posventa antigua sin detalle; requiere conciliacion.')
            cur.execute('''SELECT d.id, d.variante_id, d.cantidad, d.precio_unitario,
                           COALESCE((SELECT SUM(l.cantidad) FROM detalle_devolucion l
                                     WHERE l.detalle_venta_id = d.id AND l.direccion = 'devuelto'), 0) AS devuelta
                           FROM detalle_venta d WHERE d.venta_id = %s ORDER BY d.id''', (venta_id,))
            vendidos = cur.fetchall()
            lineas = []
            total_devuelto = Decimal(0)
            for vid, cantidad in devueltos.items():
                pendiente = cantidad
                for original in vendidos:
                    if original['variante_id'] != vid:
                        continue
                    disponible = int(original['cantidad']) - int(original['devuelta'])
                    tomar = min(pendiente, disponible)
                    if tomar > 0:
                        precio = Decimal(original['precio_unitario'])
                        lineas.append((vid, original['id'], 'devuelto', tomar, precio))
                        total_devuelto += tomar * precio
                        pendiente -= tomar
                    if not pendiente:
                        break
                if pendiente:
                    raise PostventaError(f'La variante {vid} no pertenece a la venta o supera lo pendiente de devolucion.')

            total_nuevo = Decimal(0)
            for vid, cantidad in nuevos.items():
                cur.execute('''SELECT v.stock_actual, p.precio, p.activo FROM variantes v
                               JOIN productos p ON p.id = v.producto_id WHERE v.id = %s FOR UPDATE''', (vid,))
                variante = cur.fetchone()
                if not variante or not variante['activo']:
                    raise PostventaError(f'Variante nueva {vid} inexistente o inactiva.')
                if int(variante['stock_actual']) + devueltos.get(vid, 0) < cantidad:
                    raise PostventaError(f'Stock insuficiente para la variante {vid}.')
                precio = Decimal(variante['precio'])
                lineas.append((vid, None, 'nuevo', cantidad, precio))
                total_nuevo += precio * cantidad
            diferencia = total_nuevo - total_devuelto
            dinero(total_devuelto, 'Total devuelto')
            dinero(total_nuevo, 'Total nuevo')
            dinero(abs(diferencia), 'Diferencia de pago')
            if esperada is not None and esperada != diferencia:
                raise PostventaError(f'La diferencia calculada es ${diferencia:.2f}.')
            if diferencia < 0 and medio == 'efectivo':
                cur.execute('''SELECT COALESCE(SUM(CASE WHEN tipo = 'retiro' THEN -importe
                               ELSE importe END), 0) AS saldo FROM movimientos_caja WHERE caja_id = %s''', (caja_id,))
                saldo = caja['saldo_inicial'] + cur.fetchone()['saldo']
                if saldo < -diferencia:
                    raise PostventaError('La caja no tiene efectivo suficiente para la devolucion.')

            cur.execute('''INSERT INTO devoluciones (venta_id, motivo, tipo, total_diferencia)
                           VALUES (%s, %s, %s, %s)''', (venta_id, motivo, tipo, diferencia))
            devolucion_id = cur.lastrowid
            for vid, detalle_id, direccion, cantidad, precio in lineas:
                cur.execute('''INSERT INTO detalle_devolucion
                               (devolucion_id, variante_id, detalle_venta_id, direccion, cantidad, precio_unitario)
                               VALUES (%s, %s, %s, %s, %s, %s)''',
                            (devolucion_id, vid, detalle_id, direccion, cantidad, precio))
                self.inventario_service.movimiento(
                    variante_id=vid, tipo='devolucion' if direccion == 'devuelto' else 'egreso',
                    cantidad=cantidad, motivo=f'Posventa #{devolucion_id} ({direccion}, venta #{venta_id})',
                    cursor=cur, venta_id=venta_id)
            if diferencia and medio == 'efectivo':
                cur.execute('''INSERT INTO movimientos_caja (caja_id, tipo, importe, referencia)
                               VALUES (%s, %s, %s, %s)''',
                            (caja_id, 'ingreso' if diferencia > 0 else 'retiro', abs(diferencia),
                             f'Posventa #{devolucion_id} ({tipo})'))
            cur.execute('''INSERT INTO solicitudes_postventa
                           (solicitud_id, contenido_hash, devolucion_id, caja_id, medio_pago)
                           VALUES (%s, %s, %s, %s, %s)''',
                        (solicitud_id, digest, devolucion_id, caja_id, medio))
            return {'devolucion_id': devolucion_id, 'venta_id': venta_id, 'tipo': tipo,
                    'diferencia_pago': f'{diferencia:.2f}', 'repetida': False,
                    'mensaje': 'Operacion de posventa registrada exitosamente.'}
