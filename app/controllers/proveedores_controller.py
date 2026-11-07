from flask import Blueprint, jsonify, request

from app.repositories.productos_repository import ProductosRepository
from app.services.productos_service import ErrorValidacion


bp = Blueprint("proveedores", __name__, url_prefix="/api/proveedores")
repo = ProductosRepository()


def obtener_datos():
    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        raise ErrorValidacion("Envia un objeto JSON valido.")

    nombre = str(data.get("nombre", "")).strip()
    if not nombre:
        raise ErrorValidacion("El nombre es obligatorio.")

    data["nombre"] = nombre
    return data


@bp.get("")
def listar():
    return jsonify({"datos": repo.listar_proveedores()})


@bp.post("")
def crear():
    return jsonify({
        "datos": {
            "id": repo.crear_proveedor(obtener_datos())
        }
    }), 201


@bp.patch("/<int:proveedor_id>")
def modificar(proveedor_id):
    modificado = repo.modificar_proveedor(
        proveedor_id,
        obtener_datos(),
    )
    return jsonify({"datos": {"modificado": modificado}})
