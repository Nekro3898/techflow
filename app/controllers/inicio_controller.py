from flask import Blueprint, jsonify, render_template

from app.db import get_connection


inicio_bp = Blueprint("inicio", __name__)


@inicio_bp.get("/")
def mostrar_inicio():
    return render_template("index.html")


@inicio_bp.get("/api/estado")
def consultar_estado():
    try:
        connection = get_connection()
        connection.close()
        base_datos = "conectada"
    except Exception:
        base_datos = "no disponible"

    return jsonify({
        "estado": "ok",
        "base_datos": base_datos,
        "mensaje": "El servidor de TechFlow esta funcionando.",
    })
