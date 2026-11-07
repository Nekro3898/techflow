# TechFlow

Sistema de gestion para una tienda de indumentaria con Flask y MySQL.

## Funciones

- Resumen general.
- Punto de venta con busqueda y carrito.
- Cobros en efectivo, transferencia y tarjeta.
- Pagos combinados.
- Calculo de cambio.
- Control de stock.
- Movimientos de inventario.
- Apertura y cierre de caja.
- Historial de ventas.
- Anulacion de ventas.
- Estadisticas.
- Base completa en un unico archivo SQL.
- Documentacion en `docs/documentacion.md`.

## Instalacion

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
mysql -u root -p < sql/techflow_completo.sql
.\.venv\Scripts\python.exe run.py
```

Abrir `http://127.0.0.1:5000`.

## Configuracion

Si la base no usa el usuario de ejemplo, copiar `.env.example` a `.env` y completar los datos de MySQL.
