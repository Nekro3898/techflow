from flask import Blueprint, jsonify, request

try:
    from mysql.connector import Error as MySQLError
except ImportError:
    class MySQLError(Exception):
        errno = None

from app.services.productos_service import ErrorValidacion, ProductosService


productos_bp = Blueprint("productos", __name__, url_prefix="/api")
service = ProductosService()


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
