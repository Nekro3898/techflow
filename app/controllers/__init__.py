from flask import Flask
from app.db import init_db
from app.controllers.postventa_controller import postventa_bp


def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'clave_secreta_techflow'

    init_db(app)

    app.register_blueprint(postventa_bp)

    return app