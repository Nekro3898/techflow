"""Validaciones compartidas por los servicios, independientes de Flask y SQL."""
from datetime import date
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP


class NoEncontrado(LookupError):
    pass


def objeto(value):
    if not isinstance(value, dict):
        raise ValueError('Envia un objeto JSON valido.')
    return value


def texto(value, campo, limite, opcional=False):
    if opcional and value is None:
        return None
    if not isinstance(value, str):
        raise ValueError(f'{campo} debe ser texto.')
    value = value.strip()
    if (not value and not opcional) or len(value) > limite:
        raise ValueError(f'{campo} es obligatorio y admite hasta {limite} caracteres.')
    return value


def entero(value, campo, minimo=1, maximo=2147483647):
    try:
        if isinstance(value, bool) or not isinstance(value, (str, int, float, Decimal)):
            raise ValueError()
        number = Decimal(str(value))
        if not number.is_finite() or number != number.to_integral_value() or not minimo <= number <= maximo:
            raise ValueError()
        return int(number)
    except (ValueError, InvalidOperation):
        raise ValueError(f'{campo} debe ser un entero entre {minimo} y {maximo}.') from None


def dinero(value, campo, minimo=Decimal('0.00')):
    try:
        if isinstance(value, bool) or not isinstance(value, (str, int, float, Decimal)):
            raise ValueError()
        number = Decimal(str(value))
        if not number.is_finite() or number < 0 or number > Decimal('9999999999.99'):
            raise ValueError()
        number = number.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
        if number < minimo:
            raise ValueError()
        return number
    except (ValueError, InvalidOperation):
        raise ValueError(f'{campo} debe ser un importe valido, como minimo {minimo:.2f}.') from None


def booleano(value):
    if type(value) is not bool and (type(value) is not int or value not in (0, 1)):
        raise ValueError('activo debe ser verdadero o falso.')
    return bool(value)


def rango_fechas(desde, hasta):
    for value in (desde, hasta):
        if value is not None:
            try:
                if not isinstance(value, str) or date.fromisoformat(value).isoformat() != value:
                    raise ValueError()
            except ValueError:
                raise ValueError('Las fechas deben usar el formato AAAA-MM-DD.') from None
    if desde and hasta and desde > hasta:
        raise ValueError('La fecha desde no puede ser posterior a hasta.')
    return desde, hasta
