# Base de demostración

`techflow_demo` conserva la estructura de 16 tablas de `techflow`.
Los ejemplos ficticios abarcan del 25 de octubre al 7 de noviembre de 2026:

- 12 productos, 48 variantes y 3 proveedores.
- 131 ventas: 128 completadas y 3 anuladas.
- Efectivo, transferencia, tarjeta y pagos combinados.
- 13 cajas cerradas y una abierta; dos cierres con diferencias de arqueo.
- Ingresos iniciales, reposiciones, egresos y devoluciones.
- 15 variantes con stock bajo y facturación de ventas completadas por $10.017.000.

## Usar la demo instalada

Encender MySQL de XAMPP y ejecutar `python run_demo.py` desde la raíz del proyecto.
Abrir http://127.0.0.1:5001. El lanzador no modifica `.env` y utiliza `techflow_app`,
con permisos sobre la base demo. Permite configurar `TECHFLOW_DEMO_USER` y
`TECHFLOW_DEMO_PASSWORD` en el entorno. Ya no necesita root.

## Importar en otra instalación

`techflow_demo.sql` crea la base y carga ejemplos. No contiene DROP, no modifica
techflow, no crea usuarios y no concede permisos. Importarlo solo si la base demo
no existe y detenerse ante cualquier error. El administrador debe dar al usuario
configurado SELECT, INSERT, UPDATE y DELETE sobre `techflow_demo.*`.

`python sql/generar_demo.py` regenera únicamente el archivo SQL, con fechas fijas
y una semilla determinista; no se conecta al servidor.

El SQL actualizado registra movimientos compensatorios para anulaciones y genera
identificadores compatibles con la validación actual. La base demo ya instalada
no se reimportó ni se modificó durante las correcciones de noviembre de 2026.

## Integridad

En las comprobaciones originales se verificaron totales, pagos, stock, cierres y
estructura. La revisión de código posterior utiliza bases temporales independientes.
El 8 de noviembre se reconstruyó la tabla interna de permisos mysql.db de XAMPP,
con respaldo previo, y se habilitó el usuario de aplicación para ambas bases.
No se modificaron los datos comerciales de techflow ni techflow_demo.


Actualizacion del 9 de noviembre: se agregaron las tres tablas de posventa con
`postventa.sql`, sin alterar los registros existentes. El generador ya incluye
esta estructura ampliada. Los ejemplos originales no se reimportaron.
