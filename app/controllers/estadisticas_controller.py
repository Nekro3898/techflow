from datetime import date, timedelta

from flask import Blueprint, jsonify, request

from app.services.estadisticas_service import EstadisticasService


bp = Blueprint("estadisticas", __name__, url_prefix="/api/estadisticas")
service = EstadisticasService()


def fechas():
    hoy = date.today()
    desde = request.args.get("desde") or str(hoy - timedelta(days=29))
    hasta = request.args.get("hasta") or str(hoy)
    return desde, hasta


@bp.get("/resumen")
def resumen():
    desde, hasta = fechas()
    return jsonify({"datos": service.resumen(desde, hasta)})


@bp.get("/productos")
def productos():
    desde, hasta = fechas()
    return jsonify({"datos": service.productos(desde, hasta)})


@bp.get("/ventas-por-dia")
def dias():
    desde, hasta = fechas()
    return jsonify({"datos": service.por_dia(desde, hasta)})
