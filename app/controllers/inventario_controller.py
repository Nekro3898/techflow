from flask import Blueprint, jsonify, request

from app.services.inventario_service import InventarioService


bp = Blueprint("inventario", __name__, url_prefix="/api/inventario")
service = InventarioService()


@bp.get("")
def listar():
    solo_bajo = request.args.get("solo_bajo", "").lower() in {
        "1",
        "true",
        "si",
    }
    return jsonify({
        "datos": service.listar(
            request.args.get("q", "").strip(),
            solo_bajo,
        )
    })


@bp.post("/ingresos")
def ingreso():
    data = request.get_json(silent=True) or {}
    stock = service.movimiento(
        data.get("variante_id"),
        "ingreso",
        data.get("cantidad"),
        data.get("motivo"),
    )
    return jsonify({"datos": {"stock_actual": stock}}), 201


@bp.post("/ajustes")
def ajuste():
    data = request.get_json(silent=True) or {}
    stock = service.movimiento(
        data.get("variante_id"),
        "ajuste",
        data.get("cantidad"),
        data.get("motivo"),
        True,
    )
    return jsonify({"datos": {"stock_actual": stock}})
