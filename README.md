# TechFlow Solutions

Sistema académico de gestión de una tienda de ropa, desarrollado con Flask,
MySQL/MariaDB y una interfaz HTML, CSS y JavaScript.

## Ejecutar

Con MySQL de XAMPP encendido, desde la carpeta del proyecto:

```powershell
python -m pip install -r requirements.txt
python run.py
```

Abrir http://127.0.0.1:5000. `npm start` ejecuta el mismo servidor Flask.
Para detenerlo, presionar Ctrl+C. `server.js` se conserva como ejemplo histórico
independiente; no es el servidor de la aplicación.

Para trabajar con un entorno virtual:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe run.py
```

## Configuración de la base

`app/db.py` lee `.env` mediante python-dotenv. Crear `.env` a partir de
`.env.example`, con las credenciales del usuario de aplicación:

```dotenv
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=techflow
DB_USER=techflow_app
DB_PASSWORD=techflow
```

Para una instalación nueva, ejecutar `sql/techflow.sql` como administrador.
El script crea la base, sus tablas, datos iniciales y el usuario con permisos
SELECT, INSERT, UPDATE y DELETE. Usa una collation compatible con MariaDB de XAMPP.
No elimina tablas. Si `techflow` ya existe, detener la importación: no es un script
de actualización ni se necesita volver a importarlo para aplicar cambios Python/JS.

Comprobar http://127.0.0.1:5000/api/estado: `base_datos` debe indicar `conectada`.
Un resultado `no disponible` significa que hay que revisar el servicio,
las credenciales o los permisos; no significa que falten archivos de interfaz.

## Demostración

La base paralela `techflow_demo` tiene ejemplos de 14 días y la misma estructura.
Con la demo instalada, ejecutar:

```powershell
python run_demo.py
```

Abrir http://127.0.0.1:5001. El lanzador no modifica `.env` y usa el usuario
`techflow_app`. Se pueden configurar credenciales distintas con las variables
`TECHFLOW_DEMO_USER` y `TECHFLOW_DEMO_PASSWORD`. Ver `sql/DEMO.md`.

## Organización

- `app/controllers/`: rutas HTTP y respuestas JSON.
- `app/services/`: validaciones y reglas de negocio.
- `app/repositories/`: acceso a productos, variantes, catálogos y proveedores.
- `app/models/producto.py`: clases del dominio.
- `app/db.py`: conexión, transacciones y coordinación de escrituras.
- `templates/index.html`: la interfaz existente.
- `static/css/estilos.css` y `static/js/inicio.js`: estilos y comportamiento.
- `sql/`: instalación y ejemplos.

## Funciones y reglas actuales

La interfaz incluye resumen, productos, inventario, punto de venta, historial,
caja y estadísticas. La API también permite editar/desactivar productos, administrar
variantes y proveedores y anular ventas. Esas operaciones conservan sus rutas;
no se agregaron nuevas pantallas al diseño existente.

- Los precios finales y el stock se verifican en el servidor.
- Solo se aceptan cantidades enteras y precios positivos después del redondeo.
- Un ajuste de inventario expresa el **stock final**; el historial conserva la
  dirección mediante ingreso/egreso y registra el stock anterior y el nuevo en el motivo.
- Guardar un PATCH modifica solo los campos enviados. No borra proveedor ni
  descripción ni reactiva un producto por omisión.
- Debe haber una sola caja abierta. Las escrituras de la aplicación se coordinan
  por base mediante un cerrojo de MariaDB/MySQL y transacciones.
- Las anulaciones se permiten solo mientras la caja de esa venta sigue abierta.
  Restituyen stock y registran un retiro compensatorio del efectivo; no borran el
  asiento original. Las cajas cerradas conservan su historial.
- Si se pierde la respuesta de un cobro, el navegador conserva la solicitud.
  Volver a confirmar reenvía los mismos datos, incluso después de recargar la página.
  Hasta resolverla, el carrito queda bloqueado para evitar modificar una venta incierta.
- Las fechas SQL se manejan en horario argentino UTC-03 y la API devuelve ISO 8601
  con offset; las estadísticas usan fechas inclusivas.
- El resumen distingue los últimos 30 días de los indicadores de hoy.

## Verificación

Se comprobaron sintaxis, validaciones, PATCH, movimientos, anulaciones, reintentos,
concurrencia y la interfaz en una base temporal, sin usar los datos de trabajo para
las pruebas. El detalle está en `docs/revision-2026-11-08.md`.

Los lanzadores se mantienen locales (127.0.0.1) y sin depurador. El proyecto no
incluye login/roles ni configuración de despliegue público. No versionar `.env`,
contraseñas, `.venv`, respaldos o archivos `__pycache__`.

## Equipo

- Ezequiel: arquitectura, servidor e integración.
- Maximiliano: base de datos, productos y proveedores.
- Bruno: inventario, ventas y caja.
- Abel: interfaz, estilos y manual de usuario.
- Andrés: estadísticas, reportes y textos académicos.

## Colaboración

Actualizar main, trabajar en una rama, probar los cambios y abrir un pull request
con revisión de otro integrante. Acordar cambios de tablas o contratos con quienes
los utilizan.


## Posventa (revision del 9 de noviembre de 2026)

Se mantienen las pantallas existentes. `GET /postventa` abre el historial de ventas;
no necesita una plantilla adicional. El registro se realiza por JSON en
`POST /api/postventa` o en la ruta compatible `POST /postventa/registrar`.
Esta ultima tambien acepta formularios cuyos campos de items sean listas JSON.
Ambas devuelven un comprobante JSON; no usan sesiones ni flash.

Ejemplo de devolucion parcial (reemplazar los IDs por los de la venta real):

```json
{
  "solicitud_id": "9bd1b091-38cb-4f55-a55e-6730109ea920",
  "venta_id": 1,
  "caja_id": 2,
  "tipo": "devolucion",
  "motivo": "Devolucion solicitada por el cliente",
  "medio_pago": "efectivo",
  "items_devueltos": [{"variante_id": 1, "cantidad": 1}]
}
```

Para un cambio usar `tipo: "cambio"` y agregar `items_nuevos` con el mismo formato.
El servidor usa el precio historico de los articulos originales y el precio actual
de los nuevos. `diferencia_pago` es opcional: si se envia, debe coincidir con el
importe calculado. Positivo significa cobrar; negativo, reintegrar; cero, cambio
sin diferencia. El medio puede ser efectivo, transferencia o tarjeta (efectivo
por defecto); solo efectivo afecta el saldo de caja. El registro no ejecuta cobros
ni reintegros externos en bancos o tarjetas.

Cada operacion requiere una solicitud_id nueva. Si se pierde la respuesta, repetir
exactamente la misma solicitud con el mismo ID: devuelve el comprobante existente.
Se limita lo devuelto a las unidades originales aun pendientes, incluso ante
solicitudes simultaneas. Los articulos entregados en un cambio no amplian esa cuota
original. No se permiten posventas de ventas anuladas ni anular una venta con posventa.
Se usa una caja actualmente abierta; la caja original de la venta puede estar cerrada.
Para un reintegro en efectivo debe haber saldo disponible en la caja actual.

Los informes reflejan importes y unidades netos en la fecha de cada operacion;
la cantidad de ventas conserva el numero de ventas originales. El promedio es el
neto del periodo dividido por sus ventas (cero cuando no hubo ventas). El ranking
puede incluir unidades negativas en periodos con devoluciones de ventas anteriores.

### Actualizar una instalacion existente

Ejecutar `sql/postventa.sql` sobre cada base seleccionada (techflow y, si se usa,
techflow_demo) con un usuario administrador. Es aditivo y se puede repetir; crea
`devoluciones`, `detalle_devolucion` y `solicitudes_postventa` sin borrar registros.
No contiene USE para que respete la base seleccionada. La instalacion nueva y el
SQL de demo ya incluyen las tres tablas. Las bases locales de este equipo ya se
actualizaron, con respaldo previo y verificacion de que los datos existentes no cambiaron.
Operaciones antiguas sin detalle requieren conciliacion; el sistema no inventa
cantidades para permitir nuevas devoluciones sobre esas ventas.

### Imágenes de productos

En Productos, el formulario Nuevo producto admite una imagen opcional. El botón
Cargar imagen de cada fila permite agregar o reemplazar la foto de un producto existente.
Se aceptan JPG, PNG y WebP de hasta 10 MB; el navegador reduce la imagen antes de enviarla.
El servidor vuelve a validar el contenido y guarda una copia PNG de hasta 1000 x 1000 píxeles.
Las imágenes aparecen en el catálogo del punto de venta y en el carrito.

Se almacenan en instance/imagenes_productos, separadas por conexión y base de datos.
Al trasladar o respaldar la aplicación, copiar también esa carpeta: un respaldo SQL
no incluye las fotos. No se cambió la estructura de las tablas. Instalar las dependencias
actualizadas con python -m pip install -r requirements.txt (incluye Pillow).
