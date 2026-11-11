from flask import Blueprint, jsonify, render_template, current_app, Response, send_file
from pathlib import Path
import json

from app.db import get_connection


inicio_bp = Blueprint("inicio", __name__)


@inicio_bp.get("/")
def mostrar_inicio():
    return render_template("index.html")


@inicio_bp.get('/presentacion')
def mostrar_presentacion():
    contenido = Path(current_app.static_folder) / 'presentacion' / 'contenido.json'
    return render_template('presentacion.html', diapositivas=json.loads(contenido.read_text(encoding='utf-8')))


@inicio_bp.get('/presentacion/descargar')
def descargar_presentacion():
    return Response(mostrar_presentacion(), mimetype='text/html',
                    headers={'Content-Disposition': 'attachment; filename="TechFlow-presentacion.html"'})


@inicio_bp.get('/presentacion/guia')
def descargar_guia():
    archivo = Path(current_app.root_path).parent / 'docs' / 'guia-defensa-final.html'
    return send_file(archivo, mimetype='text/html')


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
