from pathlib import Path

from flask import Flask, jsonify
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

    @app.errorhandler(LookupError)
    def not_found(error):
        return jsonify({"error": str(error)}), 404

    @app.errorhandler(MySQLError)
    def database_error(error):
        status = 409 if getattr(error, "errno", None) in {
            1062,
            1451,
            1452,
        } else 503

        return jsonify({
            "error": "No se pudo completar la operacion en la base de datos.",
        }), status

    return app
