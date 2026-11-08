from pathlib import Path
from datetime import datetime, date, timezone, timedelta

from flask import Flask, jsonify, request
from flask.json.provider import DefaultJSONProvider
from werkzeug.exceptions import HTTPException
from app.services import NoEncontrado, objeto
from mysql.connector import Error as MySQLError

from app.controllers.caja_controller import bp as caja_bp
from app.controllers.estadisticas_controller import bp as estadisticas_bp
from app.controllers.inicio_controller import inicio_bp
from app.controllers.inventario_controller import bp as inventario_bp
from app.controllers.productos_controller import productos_bp
from app.controllers.proveedores_controller import bp as proveedores_bp
from app.controllers.ventas_controller import bp as ventas_bp


def create_app():
    raiz = Path(__file__).resolve().parent.parent

    app = Flask(
        __name__,
        template_folder=str(raiz / "templates"),
        static_folder=str(raiz / "static"),
    )
    app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024

    def json_default(value):
        if isinstance(value, datetime):
            if value.tzinfo is None:
                value = value.replace(tzinfo=timezone(timedelta(hours=-3)))
            return value.isoformat()
        if isinstance(value, date):
            return value.isoformat()
        return DefaultJSONProvider.default(value)

    app.json.default = json_default

    @app.before_request
    def validar_json():
        if request.path.startswith('/api/') and request.method in {'POST', 'PATCH'}:
            objeto(request.get_json(silent=True))

    app.register_blueprint(inicio_bp)
    app.register_blueprint(productos_bp)
    app.register_blueprint(inventario_bp)
    app.register_blueprint(proveedores_bp)
    app.register_blueprint(ventas_bp)
    app.register_blueprint(caja_bp)
    app.register_blueprint(estadisticas_bp)

    @app.errorhandler(ValueError)
    def validation(error):
        return jsonify({"error": str(error)}), 400

    @app.errorhandler(NoEncontrado)
    def not_found(error):
        return jsonify({"error": str(error)}), 404

    @app.errorhandler(MySQLError)
    def database_error(error):
        app.logger.error('Error de base de datos: %s', error)
        status = 409 if getattr(error, "errno", None) in {
            1062,
            1451,
            1452,
        } else 503

        return jsonify({
            "error": "No se pudo completar la operacion en la base de datos.",
        }), status

    @app.errorhandler(HTTPException)
    def http_error(error):
        return jsonify({'error': error.description}), error.code

    @app.errorhandler(500)
    def internal_error(error):
        return jsonify({'error': 'No se pudo completar la operacion.'}), 500

    return app
