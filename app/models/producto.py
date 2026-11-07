from dataclasses import dataclass
from decimal import Decimal
from typing import Optional


@dataclass
class Producto:
    nombre: str
    categoria_id: int
    precio: Decimal
    descripcion: Optional[str] = None
    activo: bool = True
    id: Optional[int] = None


@dataclass
class Variante:
    producto_id: int
    talle_id: int
    color_id: int
    codigo: str
    stock_actual: int = 0
    stock_minimo: int = 0
    id: Optional[int] = None


@dataclass
class Catalogo:
    nombre: str
    id: Optional[int] = None
