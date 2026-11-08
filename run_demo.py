"""Arranca la demo local de XAMPP sin modificar .env ni la base original."""
import os

# Usuario de aplicacion; admite credenciales de demo configuradas en el entorno.
os.environ.update(
    DB_HOST='127.0.0.1', DB_PORT='3306', DB_NAME='techflow_demo',
    DB_USER=os.getenv('TECHFLOW_DEMO_USER', 'techflow_app'),
    DB_PASSWORD=os.getenv('TECHFLOW_DEMO_PASSWORD', 'techflow'),
)

from app import create_app

if __name__ == '__main__':
    print('DEMO: techflow_demo | http://127.0.0.1:5001')
    create_app().run(host='127.0.0.1', port=5001, debug=False)
