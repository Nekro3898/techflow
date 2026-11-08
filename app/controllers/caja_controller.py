from flask import Blueprint, jsonify, request

from app.services.caja_service import CajaService


bp = Blueprint("caja", __name__, url_prefix="/api/caja")
service = CajaService()


@bp.get("/actual")
def actual():
    return jsonify({"datos": service.actual()})


@bp.post("/aperturas")
def abrir():
    data = request.get_json(silent=True) or {}
    caja_id = service.abrir(data.get("saldo_inicial", 0))
    return jsonify({"datos": {"id": caja_id}}), 201


@bp.post("/<int:caja_id>/cierres")
def cerrar(caja_id):
    data = request.get_json(silent=True) or {}
    resultado = service.cerrar(
        caja_id,
        data.get("efectivo_contado"),
    )
    return jsonify({"datos": resultado})
