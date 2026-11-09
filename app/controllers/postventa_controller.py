from flask import Blueprint, request, jsonify, redirect, url_for
from app.services.postventa import PostventaService, PostventaError
from app.services import NoEncontrado, objeto
import json

postventa_bp = Blueprint('postventa', __name__)
postventa_service = PostventaService()


@postventa_bp.route('/postventa', methods=['GET'])
def index():
    # Se conserva la interfaz existente; no depende de una plantilla inexistente.
    return redirect(url_for('inicio.mostrar_inicio') + '#ventas')


@postventa_bp.route('/postventa/registrar', methods=['POST'])
@postventa_bp.route('/api/postventa', methods=['POST'])
def registrar():
    try:
        if request.is_json:
            data = objeto(request.get_json(silent=True))
        elif request.mimetype in {'application/x-www-form-urlencoded', 'multipart/form-data'}:
            data = request.form.to_dict()
            for campo in ('items_devueltos', 'items_nuevos'):
                if campo in data:
                    try:
                        data[campo] = json.loads(data[campo])
                    except (ValueError, TypeError):
                        raise PostventaError(f'{campo} debe ser una lista JSON.') from None
        else:
            raise PostventaError('Envia JSON o un formulario valido.')
        resultado = postventa_service.registrar_operacion(data)
        # El formulario tambien recibe un comprobante: no se pierde el resultado
        # en una redireccion ni se requiere una clave de sesion para flash().
        return jsonify({'exito': True, 'datos': resultado, 'data': resultado}), 200
    except NoEncontrado as error:
        return jsonify({'exito': False, 'error': str(error)}), 404
    except ValueError as error:
        return jsonify({'exito': False, 'error': str(error)}), 400
