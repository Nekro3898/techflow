import os
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
    }


def get_connection():
    return mysql.connector.connect(**config_db())


@contextmanager
def cursor_db(dictionary=True):
    connection = get_connection()
    cursor = connection.cursor(dictionary=dictionary)

    try:
        yield connection, cursor
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        cursor.close()
        connection.close()
