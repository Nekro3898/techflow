from flask import Blueprint, jsonify, request

from app.repositories.productos_repository import ProductosRepository
from app.services.productos_service import ErrorValidacion
from app.services import objeto, texto, booleano, NoEncontrado


bp = Blueprint("proveedores", __name__, url_prefix="/api/proveedores")
repo = ProductosRepository()


def obtener_datos():
    data = dict(objeto(request.get_json(silent=True)))
    limits = {"nombre": 150, "telefono": 40, "email": 150, "direccion": 255}
    if not data or set(data) - (limits.keys() | {"activo"}):
        raise ErrorValidacion("Campos de proveedor invalidos.")
    if request.method == "POST" and "nombre" not in data:
        raise ErrorValidacion("El nombre es obligatorio.")
    for key in data:
        data[key] = booleano(data[key]) if key == "activo" else texto(data[key], key, limits[key], key != "nombre")
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
    if not modificado:
        raise NoEncontrado("Proveedor no encontrado.")
    return jsonify({"datos": {"modificado": modificado}})
