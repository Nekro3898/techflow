# TechFlow - Documentacion

## 1. Descripcion

TechFlow es un sistema web para administrar una tienda de indumentaria. Permite cargar productos, controlar variantes y stock, abrir y cerrar caja, registrar ventas y consultar estadisticas.

La parte de ventas se maneja desde el modulo **Punto de venta**. Desde ahi se arma el carrito, se elige el medio de pago, se calcula el total y se confirma el cobro.

## 2. Tecnologias

- Python 3.11 o superior
- Flask 3.1
- MySQL 8.0 o superior
- HTML, CSS y JavaScript
- mysql-connector-python
- python-dotenv

## 3. Estructura del proyecto

```text
techflow_final/
├── app/
│   ├── controllers/
│   │   ├── caja_controller.py
│   │   ├── estadisticas_controller.py
│   │   ├── inicio_controller.py
│   │   ├── inventario_controller.py
│   │   ├── productos_controller.py
│   │   ├── proveedores_controller.py
│   │   └── ventas_controller.py
│   ├── repositories/
│   │   └── productos_repository.py
│   ├── services/
│   │   ├── caja_service.py
│   │   ├── estadisticas_service.py
│   │   ├── inventario_service.py
│   │   ├── productos_service.py
│   │   └── ventas_service.py
│   ├── db.py
│   └── __init__.py
├── docs/
│   └── documentacion.md
├── sql/
│   └── techflow_completo.sql
├── static/
│   ├── css/estilos.css
│   └── js/inicio.js
├── templates/index.html
├── .env.example
├── requirements.txt
└── run.py
```

La aplicacion esta separada por responsabilidades. Los controladores reciben las peticiones, los servicios contienen las reglas del sistema y los repositorios se ocupan de las consultas que corresponden a productos y catalogos.

## 4. Instalacion

Crear un entorno virtual:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

Crear la base de datos usando el unico archivo SQL del proyecto:

```powershell
mysql -u root -p < sql/techflow_completo.sql
```

Si se usa otra cuenta de MySQL, copiar `.env.example` a `.env` y cambiar los datos de conexion.

Ejemplo:

```text
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=techflow
DB_USER=techflow_app
DB_PASSWORD=techflow
```

Iniciar la aplicacion:

```powershell
.\.venv\Scripts\python.exe run.py
```

Abrir:

```text
http://127.0.0.1:5000
```

## 5. Punto de venta

El punto de venta tiene cuatro partes principales:

1. Busqueda de productos.
2. Carrito.
3. Medios de pago.
4. Confirmacion del cobro.

### Busqueda

Se pueden buscar las variantes por nombre de producto, codigo, talle o color. Solo se muestran variantes activas con stock disponible.

### Carrito

Al agregar una variante se guarda en el carrito la cantidad, el precio vigente y la identificacion de la variante. La cantidad no puede superar el stock disponible.

El total se calcula como:

```text
subtotal = precio_unitario x cantidad
```

```text
total = suma de todos los subtotales
```

### Pagos

Se pueden usar estos medios:

- Efectivo
- Transferencia
- Tarjeta

Tambien se pueden combinar medios. Por ejemplo:

```text
Total: $ 50000
Efectivo: $ 20000
Transferencia: $ 30000
```

El servidor exige que la suma de los pagos coincida exactamente con el total de la venta.

### Efectivo y cambio

Cuando se usa efectivo, el sistema permite ingresar el importe recibido.

```text
cambio = efectivo_recibido - efectivo_aplicado
```

El cambio solo se calcula si el efectivo recibido alcanza para cubrir la parte abonada en efectivo.

El movimiento de caja registra el importe que realmente queda en caja, no el dinero entregado por el cliente antes del cambio.

### Confirmacion

Al confirmar una venta el servidor vuelve a validar:

- Que exista una caja abierta.
- Que las variantes existan y esten activas.
- Que haya stock suficiente.
- Que las cantidades sean positivas.
- Que los medios de pago sean validos.
- Que los pagos sumen el total.
- Que el efectivo recibido alcance cuando corresponde.

La operacion se guarda dentro de una transaccion de MySQL. Si algo falla, se revierte toda la operacion.

## 6. Stock

Una venta descuenta automaticamente las cantidades de las variantes vendidas.

Cada descuento genera un movimiento de tipo `egreso` relacionado con la venta.

Los ingresos de mercaderia generan movimientos de tipo `ingreso`.

Los ajustes permiten indicar directamente el stock final y registran la diferencia.

Las anulaciones de ventas devuelven las unidades al stock y generan movimientos de tipo `devolucion`.

El stock nunca puede quedar por debajo de cero.

## 7. Caja

Solo puede existir una caja abierta al mismo tiempo.

Al abrirla se puede indicar un saldo inicial. Ese saldo se registra como movimiento de ingreso.

Las ventas en efectivo suman dinero a la caja. Las ventas pagadas solamente por transferencia o tarjeta no agregan efectivo a la caja.

Al cerrar se calcula:

```text
efectivo_esperado = saldo_inicial + ingresos + ventas_en_efectivo - retiros
```

Luego se compara con el efectivo contado:

```text
diferencia = efectivo_contado - efectivo_esperado
```

La diferencia queda guardada en la tabla `caja`.

## 8. Ventas

Cada venta tiene una cabecera y una o mas lineas de detalle.

La cabecera guarda:

- Fecha y hora
- Total
- Medio de pago principal
- Caja utilizada
- Estado
- Identificador de solicitud

El detalle guarda:

- Variante
- Cantidad
- Precio unitario aplicado
- Subtotal

Los precios de las lineas se guardan como historico. Si el precio del producto cambia despues, una venta anterior no cambia.

## 9. Reintentos de venta

El punto de venta genera un `solicitud_id` unico para cada cobro.

El servidor guarda un hash de los datos recibidos. Si una misma solicitud llega dos veces con los mismos datos, se devuelve la venta ya creada en lugar de descontar el stock otra vez.

Si el mismo identificador se reutiliza con datos diferentes, la operacion se rechaza.

## 10. Anulacion de ventas

Una venta completada puede pasar a estado `anulada` indicando un motivo.

La anulacion:

- Devuelve el stock.
- Registra los movimientos de devolucion.
- Conserva la venta y su detalle.
- Guarda el motivo.
- Elimina el importe de efectivo de la caja mediante el movimiento correspondiente.

No se elimina fisicamente el registro de la venta.

## 11. Estadisticas

Las estadisticas trabajan sobre ventas completadas dentro del periodo elegido.

El resumen muestra:

- Cantidad de ventas.
- Facturacion.
- Ticket promedio.

El ticket promedio se calcula como:

```text
promedio = facturacion / cantidad_de_ventas
```

Cuando no hay ventas, el valor queda en cero.

Tambien se muestra un ranking de productos por unidades vendidas y facturacion.

## 12. Base de datos

El archivo `sql/techflow_completo.sql` contiene todo lo necesario para una instalacion nueva.

Tablas principales:

- `categorias`
- `proveedores`
- `productos`
- `talles`
- `colores`
- `variantes`
- `caja`
- `ventas`
- `detalle_venta`
- `pagos_venta`
- `solicitudes_venta`
- `movimientos_stock`
- `movimientos_caja`

Las relaciones usan claves foraneas y las tablas de ventas y stock conservan el historial.

## 13. Datos de prueba

El SQL incluye datos iniciales para poder entrar al sistema y probar el recorrido completo sin cargar todo desde cero.

Tambien deja una caja abierta con saldo inicial cero para probar el punto de venta inmediatamente despues de importar la base.

## 14. Prueba recomendada

Para comprobar el sistema completo:

1. Importar `sql/techflow_completo.sql`.
2. Iniciar Flask.
3. Entrar a `Punto de venta`.
4. Seleccionar una variante con stock.
5. Agregar una cantidad al carrito.
6. Completar el pago.
7. Confirmar el cobro.
8. Revisar que baje el stock.
9. Revisar la venta en `Ventas`.
10. Revisar el efectivo en `Caja`.
11. Revisar los datos en `Estadisticas`.

## 15. Respaldo

Para hacer un respaldo de la base:

```bash
mysqldump -u root -p --single-transaction --routines --triggers techflow > respaldo_techflow.sql
```

Para restaurarlo en una base de prueba:

```bash
mysql -u root -p techflow < respaldo_techflow.sql
```

## 16. Criterio general del proyecto

La aplicacion busca mantener la logica importante del lado del servidor. La pantalla ayuda a cargar y mostrar datos, pero el servidor es quien decide si una venta se puede guardar, cuanto debe cobrar y cuanto stock se puede descontar.

Esto evita depender de los calculos del navegador para datos que afectan a la caja, las ventas y el inventario.
