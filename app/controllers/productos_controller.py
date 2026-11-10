from flask import Blueprint, jsonify, request, current_app, send_file, Response
from pathlib import Path
from io import BytesIO
import base64
import binascii
import hashlib
import os
import uuid
from PIL import Image, ImageOps, UnidentifiedImageError
from app.db import config_db

try:
    from mysql.connector import Error as MySQLError
except ImportError:
    class MySQLError(Exception):
        errno = None

from app.services.productos_service import ErrorValidacion, ProductosService


productos_bp = Blueprint("productos", __name__, url_prefix="/api")
service = ProductosService()


@productos_bp.route('/productos/<int:producto_id>/imagen', methods=['GET', 'POST'])
def imagen_producto(producto_id):
    # Separar archivos por conexión/base para no mezclar la demo y la aplicación.
    config = config_db()
    clave = hashlib.sha256(f"{config['host']}:{config['port']}:{config['database']}".encode()).hexdigest()
    carpeta = Path(current_app.instance_path) / 'imagenes_productos' / clave
    destino = carpeta / f'{producto_id}.png'
    if request.method == 'GET':
        if destino.is_file():
            return send_file(BytesIO(destino.read_bytes()), mimetype='image/png', max_age=0)
        return Response('<svg xmlns="http://www.w3.org/2000/svg" width="240" height="160"><rect width="100%" height="100%" fill="#eef2f7"/><text x="50%" y="50%" text-anchor="middle" fill="#64748b" font-family="sans-serif" font-size="16">Sin imagen</text></svg>', mimetype='image/svg+xml', headers={'Cache-Control': 'no-store'})
    if not service.repo.obtener_producto(producto_id):
        return jsonify({'error': 'Producto no encontrado.'}), 404
    data = request.get_json(silent=True) or {}
    try:
        contenido = base64.b64decode(data.get('imagen', ''), validate=True)
        if not contenido or len(contenido) > 700000:
            raise ValueError('La imagen debe ocupar menos de 700 KB.')
        with Image.open(BytesIO(contenido)) as original:
            if original.format not in {'PNG', 'JPEG', 'WEBP'} or original.width * original.height > 16000000:
                raise ValueError('Usá una imagen PNG, JPG o WebP de hasta 16 megapíxeles.')
            imagen = ImageOps.exif_transpose(original).convert('RGB')
            imagen.thumbnail((1000, 1000))
            salida = BytesIO()
            imagen.save(salida, format='PNG')
    except (binascii.Error, TypeError, UnidentifiedImageError, OSError, Image.DecompressionBombError) as error:
        raise ValueError('El archivo no es una imagen válida.') from error
    carpeta.mkdir(parents=True, exist_ok=True)
    temporal = carpeta / f'{uuid.uuid4().hex}.tmp'
    try:
        temporal.write_bytes(salida.getvalue())
        os.replace(temporal, destino)
    finally:
        temporal.unlink(missing_ok=True)
    return jsonify({'mensaje': 'Imagen guardada.'})


@productos_bp.errorhandler(ErrorValidacion)
def err_validacion(error):
    return jsonify({"error": str(error)}), 400


@productos_bp.errorhandler(MySQLError)
def err_db(error):
    status = 409 if getattr(error, "errno", None) in {
        1062,
        1451,
        1452,
    } else 503

    return jsonify({
        "error": "No se pudo completar la operacion en la base de datos.",
    }), status


@productos_bp.get("/productos")
def listar():
    return jsonify({
        "datos": service.listar(
            request.args.get("q", "").strip(),
            request.args.get("incluir_inactivos", "").lower()
            in {"1", "true", "si"},
        )
    })


@productos_bp.post("/productos")
def crear():
    producto_id = service.crear(request.get_json(silent=True))
    return jsonify({
        "id": producto_id,
        "mensaje": "Producto creado.",
    }), 201


@productos_bp.post('/productos/carga')
def crear_con_variantes():
    producto_id = service.crear_con_variantes(request.get_json(silent=True))
    return jsonify({'id': producto_id, 'mensaje': 'Producto y variantes guardados.'}), 201


@productos_bp.get("/productos/<int:producto_id>")
def obtener(producto_id):
    producto = service.repo.obtener_producto(producto_id)

    if not producto:
        return jsonify({"error": "Producto no encontrado."}), 404

    return jsonify({"datos": producto})


@productos_bp.patch("/productos/<int:producto_id>")
def modificar(producto_id):
    modificado = service.modificar(
        producto_id,
        request.get_json(silent=True),
    )

    if not modificado:
        return jsonify({"error": "Producto no encontrado."}), 404

    return jsonify({"mensaje": "Producto modificado."})


@productos_bp.post("/productos/<int:producto_id>/desactivacion")
def desactivar(producto_id):
    desactivado = service.desactivar(producto_id)

    if not desactivado:
        return jsonify({"error": "Producto no encontrado."}), 404

    return jsonify({
        "mensaje": "Producto desactivado; se conserva el historial.",
    })


@productos_bp.get("/<string:tabla>")
def listar_catalogo(tabla):
    if tabla not in {"categorias", "talles", "colores"}:
        return jsonify({"error": "Catalogo no encontrado."}), 404

    return jsonify({"datos": service.catalogo(tabla)})


@productos_bp.post("/<string:tabla>")
def crear_catalogo(tabla):
    if tabla not in {"categorias", "talles", "colores"}:
        return jsonify({"error": "Catalogo no encontrado."}), 404

    catalogo_id = service.crear_catalogo(
        tabla,
        request.get_json(silent=True),
    )
    return jsonify({
        "id": catalogo_id,
        "mensaje": "Elemento creado.",
    }), 201


@productos_bp.get("/productos/<int:producto_id>/variantes")
def listar_variantes(producto_id):
    return jsonify({
        "datos": service.variantes(producto_id),
    })


@productos_bp.post("/productos/<int:producto_id>/variantes")
def crear_variante(producto_id):
    data = request.get_json(silent=True)

    if isinstance(data, dict):
        data["producto_id"] = producto_id

    variante_id = service.crear_variante(data)
    return jsonify({
        "id": variante_id,
        "mensaje": "Variante creada con stock inicial cero.",
    }), 201


@productos_bp.patch("/variantes/<int:variante_id>")
def modificar_variante(variante_id):
    modificado = service.modificar_variante(
        variante_id,
        request.get_json(silent=True),
    )

    if not modificado:
        return jsonify({"error": "Variante no encontrada."}), 404

    return jsonify({
        "mensaje": "Variante modificada; el stock actual no se altera.",
    })
