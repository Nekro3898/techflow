from decimal import Decimal
from app.services import objeto, texto, entero, dinero, booleano

from app.repositories.productos_repository import ProductosRepository


class ErrorValidacion(ValueError):
    pass


class ProductosService:
    def __init__(self):
        self.repo = ProductosRepository()

    @staticmethod
    def precio(value):
        return dinero(value, "Precio", Decimal("0.01"))

    @staticmethod
    def validar_campos(data, variante=False):
        data = dict(objeto(data))
        allowed = ({"producto_id", "talle_id", "color_id", "codigo", "stock_minimo"}
                   if variante else {"nombre", "descripcion", "categoria_id", "proveedor_id", "precio", "activo"})
        if not data or set(data) - allowed:
            raise ErrorValidacion("Envia solo los campos editables de este recurso.")
        for key in data:
            if key in {"producto_id", "categoria_id", "talle_id", "color_id", "proveedor_id"}:
                if key != "proveedor_id" or data[key] is not None:
                    data[key] = entero(data[key], key)
            elif key == "stock_minimo":
                data[key] = entero(data[key], key, 0)
            elif key == "precio":
                data[key] = ProductosService.precio(data[key])
            elif key == "activo":
                data[key] = booleano(data[key])
            else:
                limit = {"nombre": 150, "descripcion": 10000, "codigo": 80}[key]
                data[key] = texto(data[key], key, limit, key == "descripcion")
        return data

    def listar(self, query="", incluir_inactivos=False):
        return self.repo.listar_productos(query, incluir_inactivos)

    def crear(self, data):
        data = self.validar_campos(data)
        if not {"nombre", "precio", "categoria_id"} <= data.keys():
            raise ErrorValidacion("Nombre, precio y categoria son obligatorios.")
        return self.repo.crear_producto(data)

    def modificar(self, producto_id, data):
        return self.repo.modificar_producto(producto_id, self.validar_campos(data))

    def crear_con_variantes(self, data):
        data = objeto(data)
        categoria = texto(data.get('categoria_nueva'), 'Nueva categoría', 100, True)
        producto = self.validar_campos(data.get('producto'))
        if not {'nombre', 'precio'} <= producto.keys() or (not categoria and not producto.get('categoria_id')):
            raise ErrorValidacion('Nombre, precio y categoría son obligatorios.')
        if categoria and producto.get('categoria_id'):
            raise ErrorValidacion('Elegí una categoría existente o una nueva.')
        filas = data.get('variantes')
        if not isinstance(filas, list) or not 1 <= len(filas) <= 200:
            raise ErrorValidacion('Completá entre 1 y 200 combinaciones de talle y color.')
        variantes, vistas = [], set()
        for fila in filas:
            fila = objeto(fila)
            talle = texto(fila.get('talle'), 'Talle', 40) if 'talle' in fila else entero(fila.get('talle_id'), 'Talle')
            color = texto(fila.get('color'), 'Color', 60) if 'color' in fila else entero(fila.get('color_id'), 'Color')
            if (talle, color) in vistas:
                raise ErrorValidacion('Hay combinaciones de talle y color repetidas.')
            vistas.add((talle, color))
            variantes.append({'talle_id': talle if isinstance(talle, int) else None,
                'color_id': color if isinstance(color, int) else None,
                'talle': talle if isinstance(talle, str) else None,
                'color': color if isinstance(color, str) else None,
                'stock': entero(fila.get('stock'), 'Stock inicial', 0),
                'minimo': entero(fila.get('stock_minimo', 0), 'Stock mínimo', 0)})
        return self.repo.crear_con_variantes(producto, categoria, variantes)

    def desactivar(self, producto_id):
        return self.repo.desactivar_producto(producto_id)

    def catalogo(self, tabla):
        return self.repo.listar_catalogo(tabla)

    def crear_catalogo(self, tabla, data):
        limites = {"categorias": 100, "talles": 40, "colores": 60}
        return self.repo.crear_catalogo(tabla, texto(objeto(data).get("nombre"), "Nombre", limites[tabla]))

    def variantes(self, producto_id):
        return self.repo.listar_variantes(producto_id)

    def crear_variante(self, data):
        data = self.validar_campos(data, variante=True)
        if not {"producto_id", "talle_id", "color_id", "codigo"} <= data.keys():
            raise ErrorValidacion("Producto, talle, color y codigo son obligatorios.")
        return self.repo.crear_variante(data)

    def modificar_variante(self, variante_id, data):
        data = self.validar_campos(data, variante=True)
        if "producto_id" in data:
            raise ErrorValidacion("No se puede cambiar el producto de una variante.")
        return self.repo.modificar_variante(variante_id, data)
