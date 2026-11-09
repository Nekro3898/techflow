def create_app():
    """Compatibilidad: una sola fabrica configura todos los modulos."""
    from app import create_app as crear_aplicacion
    return crear_aplicacion()
