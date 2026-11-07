from flask import Blueprint, jsonify, request

from app.services.ventas_service import VentasService


bp = Blueprint("ventas", __name__, url_prefix="/api/ventas")
service = VentasService()


@bp.post("")
def crear():
    resultado = service.crear(request.get_json(silent=True))
    return jsonify({"datos": resultado}), 201


@bp.get("")
def listar():
    return jsonify({
        "datos": service.listar(
            request.args.get("desde"),
            request.args.get("hasta"),
            request.args.get("estado"),
        )
    })


@bp.get("/<int:venta_id>")
def detalle(venta_id):
    venta = service.detalle(venta_id)

    if not venta:
        return jsonify({"error": "Venta no encontrada."}), 404

    return jsonify({"datos": venta})


@bp.post("/<int:venta_id>/anulacion")
def anular(venta_id):
    data = request.get_json(silent=True) or {}
    service.anular(venta_id, data.get("motivo", ""))
    return jsonify({
        "mensaje": "Venta anulada.",
        "datos": True,
    })
