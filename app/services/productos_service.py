from decimal import Decimal, InvalidOperation

from app.repositories.productos_repository import ProductosRepository


class ErrorValidacion(ValueError):
    pass


class ProductosService:
    def __init__(self):
        self.repo = ProductosRepository()

    @staticmethod
    def validar_data(data):
        if not isinstance(data, dict):
            raise ErrorValidacion("Envia un objeto JSON valido.")
        return data

    @staticmethod
    def nombre(data):
        data = ProductosService.validar_data(data)
        nombre = str(data.get("nombre", "")).strip()
        if not nombre:
            raise ErrorValidacion("El nombre es obligatorio.")
        return nombre

    @staticmethod
    def precio(value):
        try:
            precio = Decimal(str(value))
        except (InvalidOperation, TypeError):
            raise ErrorValidacion("El precio debe ser numerico.")

        if precio <= 0:
            raise ErrorValidacion("El precio debe ser mayor que cero.")

        return precio.quantize(Decimal("0.01"))

    def listar(self, query="", incluir_inactivos=False):
        return self.repo.listar_productos(query, incluir_inactivos)

    def crear(self, data):
        data = self.validar_data(data)
        nombre = self.nombre(data)
        precio = self.precio(data.get("precio"))

        try:
            categoria_id = int(data.get("categoria_id", 0))
        except (TypeError, ValueError):
            categoria_id = 0

        if categoria_id <= 0:
            raise ErrorValidacion("La categoria es obligatoria.")

        return self.repo.crear_producto({
            **data,
            "nombre": nombre,
            "precio": precio,
            "categoria_id": categoria_id,
        })

    def modificar(self, producto_id, data):
        data = self.validar_data(data)
        nombre = self.nombre(data)
        precio = self.precio(data.get("precio"))

        try:
            categoria_id = int(data.get("categoria_id", 0))
        except (TypeError, ValueError):
            categoria_id = 0

        if categoria_id <= 0:
            raise ErrorValidacion("La categoria es obligatoria.")

        return self.repo.modificar_producto(
            producto_id,
            {
                **data,
                "nombre": nombre,
                "precio": precio,
                "categoria_id": categoria_id,
            },
        )

    def desactivar(self, producto_id):
        return self.repo.desactivar_producto(producto_id)

    def catalogo(self, tabla):
        return self.repo.listar_catalogo(tabla)

    def crear_catalogo(self, tabla, data):
        return self.repo.crear_catalogo(tabla, self.nombre(data))

    def variantes(self, producto_id):
        return self.repo.listar_variantes(producto_id)

    def crear_variante(self, data):
        data = self.validar_data(data)

        for key in ("producto_id", "talle_id", "color_id"):
            try:
                value = int(data.get(key, 0))
            except (TypeError, ValueError):
                value = 0

            if value <= 0:
                raise ErrorValidacion(f"{key} es obligatorio.")

        codigo = str(data.get("codigo", "")).strip()
        if not codigo:
            raise ErrorValidacion("El codigo de variante es obligatorio.")

        try:
            minimo = int(data.get("stock_minimo", 0))
        except (TypeError, ValueError):
            raise ErrorValidacion("El stock minimo no es valido.")

        if minimo < 0:
            raise ErrorValidacion("El stock minimo no puede ser negativo.")

        return self.repo.crear_variante({
            **data,
            "codigo": codigo,
            "stock_minimo": minimo,
        })

    def modificar_variante(self, variante_id, data):
        data = self.validar_data(data)
        codigo = str(data.get("codigo", "")).strip()

        try:
            minimo = int(data.get("stock_minimo", 0))
            talle_id = int(data.get("talle_id", 0))
            color_id = int(data.get("color_id", 0))
        except (TypeError, ValueError):
            raise ErrorValidacion("Los datos de la variante no son validos.")

        if not codigo or minimo < 0 or talle_id <= 0 or color_id <= 0:
            raise ErrorValidacion("Los datos de la variante son obligatorios.")

        return self.repo.modificar_variante(
            variante_id,
            {
                **data,
                "codigo": codigo,
                "stock_minimo": minimo,
                "talle_id": talle_id,
                "color_id": color_id,
            },
        )
