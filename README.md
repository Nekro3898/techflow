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
