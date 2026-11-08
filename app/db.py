import os
import hashlib
from contextlib import contextmanager

import mysql.connector
from dotenv import load_dotenv


load_dotenv()


def config_db():
    return {
        "host": os.getenv("DB_HOST", "127.0.0.1"),
        "port": int(os.getenv("DB_PORT", "3306")),
        "database": os.getenv("DB_NAME", "techflow"),
        "user": os.getenv("DB_USER", "techflow_app"),
        "password": os.getenv("DB_PASSWORD", "techflow"),
        "charset": "utf8mb4",
        "collation": "utf8mb4_unicode_ci",
        "connection_timeout": 5,
    }


def get_connection():
    connection = mysql.connector.connect(**config_db())
    try:
        connection.time_zone = '-03:00'
        connection.start_transaction(isolation_level='READ COMMITTED')
        return connection
    except Exception:
        connection.close()
        raise


@contextmanager
def cursor_db(dictionary=True, escritura=False):
    connection = get_connection()
    cursor = None
    lock_name = None

    try:
        cursor = connection.cursor(dictionary=dictionary)
        if escritura:
            # Un cerrojo por base coordina operaciones tambien entre procesos.
            name = 'techflow:' + hashlib.sha256(connection.database.encode()).hexdigest()[:48]
            cursor.execute('SELECT GET_LOCK(%s, 10) AS adquirido', (name,))
            result = cursor.fetchone()
            acquired = result['adquirido'] if dictionary else result[0]
            if acquired != 1:
                raise mysql.connector.Error('Otra operacion esta en curso; reintenta.', errno=1205)
            lock_name = name
        yield connection, cursor
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        try:
            if cursor is not None:
                if lock_name:
                    cursor.execute('SELECT RELEASE_LOCK(%s)', (lock_name,))
                    cursor.fetchone()
                cursor.close()
        finally:
            connection.close()
