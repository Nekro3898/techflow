# TechFlow — Guía de defensa final

Preparación para Ingeniería de Software, Base de Datos y Programación. Referencia: 11/11/2026.

## Cómo usar el material

Abrir TechFlow y elegir **Presentación**. Flechas para navegar, N para notas, F para pantalla completa. El índice permite saltar a cualquier tema. **Descargar HTML** crea una copia autónoma con los diagramas y la captura incluidos. **Imprimir / PDF** permite guardar las diapositivas desde el navegador. La copia HTML también se entrega como `TechFlow-presentacion.html`.

El recorrido principal ocupa 28 diapositivas cortas y deja dos anexos de consulta. Ensayar 20–25 minutos de explicación más 5 minutos de demostración; ajustar el tiempo a lo indicado por el docente. Las notas son apoyo para hablar, no texto para leer literalmente.

## Preparación del equipo

- Completar oralmente integrantes y contribuciones reales; no inventar roles ni una metodología formal.
- Cada integrante debe poder seguir una operación desde JavaScript hasta SQL.
- Iniciar MariaDB y `python run_demo.py`; abrir http://127.0.0.1:5001.
- Revisar caja abierta y stock disponible. Las ventas de la exposición modifican la demo.
- Guardar copia SQL y la carpeta `instance/imagenes_productos`. El SQL no incluye fotos.
- Llevar el HTML autónomo como respaldo. Para mostrar las diapositivas no se necesita MySQL.
- Reconocer la asistencia de IA y poder explicar el código que se presenta.

## Guion diapositiva por diapositiva

### 01. TechFlow

Presentar a los integrantes y explicar el problema del negocio. Esta defensa se centra en la implementación actual, no en atribuir tecnologías que solo se estudiaron. Duración sugerida: 20–25 minutos más demostración. Fecha de referencia: 11 de noviembre de 2026.

**Código o evidencia:** `Proyecto TechFlow`.

### 02. Una tienda, varios datos conectados

Ejemplo: vender una remera negra talle M no debe descontar una blanca talle L. El objetivo es sustituir registros dispersos por operaciones relacionadas y verificables.

**Código o evidencia:** `templates/index.html · sql/techflow.sql`.

### 03. Qué permite hacer TechFlow

Aclarar que posventa está implementada en el servidor pero no tiene pantalla propia. No se implementaron usuarios, roles ni autorización. No es una tienda en línea ni una pasarela bancaria: registra pagos.

**Código o evidencia:** `app/controllers/ · templates/index.html`.

### 04. Recorrido del desarrollo

Es una síntesis del recorrido observable en el repositorio y en las mejoras del proyecto; no una cronología con fechas o autorías inventadas. Git conserva cambios del equipo. Mostrar git log y un diff real. Las mejoras fueron iterativas, sin afirmar que se aplicó Scrum formalmente.

**Código o evidencia:** `Git: 3d5a79d, fc07aa9, 3ac8868, c0548a5 · docs/`.

### 05. Diagrama de casos de uso

El actor es quien interactúa con el sistema. El cliente compra en la tienda, pero no opera esta interfaz. La base de datos no se representa como actor de negocio. Los casos de uso describen objetivos, no botones ni tablas. No hay include entre abrir caja y cada venta: caja abierta es una precondición. El diagrama completo editable también se conserva en docs/casos-uso-techflow.puml.

**Código o evidencia:** `app/controllers/ · docs/casos-uso-techflow.puml`.

### 06. Caso de uso: registrar una venta

El flujo feliz no es suficiente. Si se pierde la respuesta después de guardar, el reintento utiliza el mismo identificador para no repetir el cobro. Si falla la transacción, se revierten los cambios. El cierre de caja no debe mezclarse con una venta concurrente.

**Código o evidencia:** `app/services/ventas_service.py: crear · static/js/inicio.js: confirmarCobro`.

### 07. Lo aprendido y lo aplicado

No es necesario incorporar todas las tecnologías para demostrar que se conocen. Tkinter crea interfaces de escritorio; HTML/CSS/JS permiten acceso desde navegador. React es una biblioteca de interfaces, Vite una herramienta de desarrollo y construcción, Node un entorno de ejecución de JavaScript. PHP puede procesar solicitudes en servidor. La aplicación elegida usa Flask. npm start solo lanza Python.

**Código o evidencia:** `requirements.txt · package.json · run.py · templates/index.html`.

### 08. Tecnologías elegidas

Distinguir lenguaje, biblioteca, framework y motor de base de datos. HTML es marcado; CSS estilos; JSON es un formato de intercambio. Flask utiliza Jinja para entregar la plantilla inicial. No se utiliza un ORM: el SQL está escrito explícitamente.

**Código o evidencia:** `requirements.txt · app/db.py · app/controllers/productos_controller.py`.

### 09. Modelo, vista y controlador

MVC separa presentación, coordinación de solicitudes y estado/reglas. Facilita mantenimiento y cambios localizados. Esta arquitectura se basa en MVC con capas adicionales. Algunos servicios contienen SQL y proveedores valida en el controlador: la separación no es uniforme ni MVC puro. La respuesta vuelve hacia la vista.

**Código o evidencia:** `app/controllers/productos_controller.py · app/services/productos_service.py · app/repositories/productos_repository.py`.

### 10. Un producto atraviesa las capas

Mostrar el endpoint en el controlador y abrir el método del servicio. El servicio valida nombre, precio, combinaciones y cantidades. El repositorio guarda categoría, producto, variantes y stock inicial en una transacción. La foto se sube en una solicitud separada: no afirmar que el archivo y SQL son una única transacción.

**Código o evidencia:** `app/controllers/productos_controller.py: crear_con_variantes · app/repositories/productos_repository.py: crear_con_variantes`.

### 11. Objetos que colaboran

Fragmento del código actual, con salto de línea para legibilidad. Clase define estructura/comportamiento; objeto es una instancia; método es una operación. Se crea el servicio al importar el controlador y su constructor crea el repositorio. Encapsulación aquí significa agrupar responsabilidades, no atributos privados estrictos.

**Código o evidencia:** `app/services/productos_service.py · app/controllers/productos_controller.py: service = ProductosService()`.

### 12. Dónde se aplica POO y hasta dónde llega

Explicar por qué sirve: cambios más localizados, reutilización y responsabilidades comprensibles. No afirmar que usar clases implica cumplir todos los principios de diseño. No hay clases de dominio Producto/Variante integradas: las dataclasses sin uso se eliminaron. El tratamiento de excepciones permite manejar subtipos; no hay jerarquía de pagos con implementaciones intercambiables.

**Código o evidencia:** `app/services/productos_service.py · postventa.py · inventario_service.py · ventas_service.py`.

### 13. Diagrama de clases de implementación

UML no es solamente un diagrama de tablas: incluye clases, casos de uso y secuencia. Estas son clases reales, con métodos seleccionados. Los módulos de controladores y la función cursor_db no se dibujan como clases inexistentes. Otras clases reales: CajaService, VentasService y EstadisticasService.

**Código o evidencia:** `app/services/ · app/repositories/productos_repository.py`.

### 14. Por qué una base relacional

No decir que NoSQL carece siempre de relaciones o transacciones: depende del motor. MySQL y MariaDB son motores distintos relacionados; en esta instalación XAMPP provee MariaDB. XAMPP es el paquete que facilita iniciar servicios, no una base ni un lenguaje.

**Código o evidencia:** `sql/techflow.sql · app/db.py`.

### 15. Relaciones principales

PK identifica una fila; FK referencia otra tabla. Una venta contiene varias líneas y varios pagos. Categoría y proveedor no se repiten como textos en cada línea vendida. Talles y colores se reutilizan. El diagrama expresa relaciones principales, no todas las columnas ni cardinalidades mínimas.

**Código o evidencia:** `sql/techflow.sql`.

### 16. Producto, variante y SKU

Se guarda en variantes.codigo con UNIQUE. La carga por grilla genera el siguiente SKU a partir del mayor existente con ese formato, dentro de un bloqueo de escritura. No es una columna AUTO_INCREMENT separada. No prometer secuencia sin huecos ni no reutilización tras borrados manuales. Dos unidades iguales comparten SKU.

**Código o evidencia:** `app/repositories/productos_repository.py: crear_con_variantes · sql/techflow.sql: variantes`.

### 17. Primera y segunda forma normal

Tener un id no basta para demostrar 2FN: revisar todas las claves candidatas. Variantes tiene id, código y la combinación de tres claves. Bajo las dependencias del negocio actual, stock/minimo dependen de la variante completa. El precio actual se guarda en productos. El esquema trabaja en 1FN y 2FN según esas reglas.

**Código o evidencia:** `sql/techflow.sql: UNIQUE KEY uq_variante`.

### 18. Tercera forma normal: límites reales

Definición formal: para X→A no trivial, X es superclave o A es atributo primo. Cantidad/precio determinan subtotal sin identificar la fila: excepción concreta. Los agregados entre tablas no prueban por sí solos violación formal de 3FN, pero exigen consistencia. En devoluciones también se repite la variante del detalle de origen. Guardar precio histórico no es un error: representa otro hecho temporal.

**Código o evidencia:** `sql/techflow.sql: detalle_venta, caja, detalle_devolucion`.

### 19. Una venta se guarda completa

Es pseudocódigo del recorrido, no un fragmento literal completo. Atomicidad: todo o nada. Consistencia: reglas y restricciones. Aislamiento: READ COMMITTED y bloqueo de escrituras por base, además de SELECT FOR UPDATE donde corresponde. Durabilidad: depende del motor/configuración de persistencia; no equivale a respaldo. Serializar escrituras prioriza consistencia en esta escala, con costo de concurrencia.

**Código o evidencia:** `app/db.py: cursor_db · app/services/ventas_service.py: crear`.

### 20. Carga de productos y variantes

Mostrar Nuevo producto sin guardar datos de prueba innecesarios. Una celda vacía no crea variante; cero crea variante sin stock. Se reutilizan catálogos existentes y se rechazan combinaciones duplicadas. El producto y variantes son transaccionales. No afirmar que Modificar permite editar toda la grilla: esa pantalla modifica campos generales.

**Código o evidencia:** `static/js/inicio.js: mostrarProducto, actualizarGrillaProducto, guardarProducto, modificarProducto`.

### 21. Imágenes, historial y estadísticas

Las imágenes no son BLOBs en SQL: se guardan en instance/imagenes_productos, separadas por conexión/base e ID de producto. La paginación actual es del lado del navegador: la API aún entrega todos los registros. El gráfico SVG funciona sin bibliotecas externas y muestra días con movimientos. Las estadísticas descuentan anulaciones y consideran diferencias de posventa.

**Código o evidencia:** `app/controllers/productos_controller.py: imagen_producto · static/js/inicio.js: tablaPaginada, dibujarGraficoVentas`.

### 22. La información vuelve al negocio

El gráfico permite comparar días; no predice ventas futuras. Mostrar filtros, una barra y la tabla alternativa. La captura es evidencia de la interfaz, no un reporte actualizado de producción.

**Código o evidencia:** `Captura local de TechFlow · static/js/inicio.js: cargarStats`.

### 23. Mapa de carpetas

Recorrer la estructura en el editor. No abrir ni proyectar credenciales. No hay carpeta models funcional: se retiraron clases sin uso. Modelo en MVC es un rol arquitectónico, no el nombre obligatorio de una carpeta. El anexo de la guía enumera cada archivo fuente.

**Código o evidencia:** `Árbol del repositorio revisado el 11/11/2026`.

### 24. Cómo arranca y se comunica

Apache no participa en este arranque. Cerrar el panel XAMPP no siempre detiene el servicio. La presentación puede abrirse como archivo HTML independiente sin Flask; para operar ventas se necesitan Flask y la base. No crear otra base llamada posventa: postventa.sql agrega tablas a la base seleccionada.

**Código o evidencia:** `run.py · run_demo.py · app/__init__.py · app/db.py`.

### 25. Pruebas y correcciones

Se usaron pruebas con Flask test_client, scripts de regresión, bases temporales y recorridos en navegador. Hubo una ejecución de 141 comprobaciones de negocio antes de mejoras posteriores; no presentarla como certificación exhaustiva de cada cambio actual. Los tests son evidencia de escenarios, no garantía de perfección. Mostrar casos concretos y mensajes de rechazo sin alterar datos reales.

**Código o evidencia:** `docs/revision-2026-11-08.md · app/services/ · pruebas de desarrollo`.

### 26. Cómo trabajamos y qué aprendimos

La asistencia de IA formó parte del trabajo en este chat. No atribuir toda la implementación manual a una persona ni inventar reparto de tareas. Cada integrante debe explicar los módulos que conoce y completar oralmente su contribución real. Si el docente pregunta por metodología, hablar de iteración y control de versiones observables; no inventar ceremonias ágiles.

**Código o evidencia:** `Historial Git y proceso de revisión del proyecto`.

### 27. Recorrido en vivo

Usar la demo. La venta de la exposición sí modifica sus registros. Ensayar con caja abierta y stock disponible. Antes de confirmar, avisar que es una operación de demostración. Llevar el HTML descargado como respaldo si no arranca la app. No cambiar ni regenerar la base durante la exposición.

**Código o evidencia:** `run_demo.py · interfaz de TechFlow`.

### 28. Alcance y próximas mejoras

Cerrar relacionando las tres materias: programación construye el comportamiento, base de datos conserva relaciones e integridad, ingeniería organiza requisitos y responsabilidades. No afirmar listo para producción ni 3FN estricta completa. Dejar tiempo para preguntas.

**Código o evidencia:** `Código y alcance actual`.

### 29. Las 16 tablas y su función

Solicitudes permiten identificar operaciones y prevenir duplicación. solicitudes_venta no tiene FK explícita hacia ventas: la relación se mantiene por lógica. Posventa guarda detalle de lo devuelto/nuevo y no borra la venta original. Las 16 tablas no incluyen archivos de imágenes.

**Código o evidencia:** `sql/techflow.sql`.

### 30. Preguntas para la defensa

Practicar respuestas con ejemplos, no definiciones aisladas. Para normalización, abrir detalle_venta y explicar subtotal y precio histórico. Para MVC, seguir una ruta desde JS hasta SQL. Para SKU, distinguir código de variante e ID interno.

**Código o evidencia:** `Guía de defensa y código del proyecto`.

## Inventario de archivos y responsabilidades

| Archivo | Función |
|---|---|
| `app/__init__.py` | Crea Flask, registra Blueprints, serializa fechas y maneja errores HTTP/SQL. |
| `app/db.py` | Lee configuración, conecta con MariaDB y controla commit, rollback y bloqueo de escritura. |
| `app/controllers/__init__.py` | Compatibilidad: delega en la fábrica create_app principal. |
| `app/controllers/inicio_controller.py` | Entrega la aplicación, el estado y la presentación/descargas. |
| `app/controllers/productos_controller.py` | API de productos, carga por grilla, catálogos, variantes e imágenes. |
| `app/controllers/proveedores_controller.py` | API y validación de proveedores. |
| `app/controllers/inventario_controller.py` | Consultas de existencias, ingresos y ajustes. |
| `app/controllers/ventas_controller.py` | Registro, historial, detalle y anulación de ventas. |
| `app/controllers/caja_controller.py` | Caja actual, apertura y cierre. |
| `app/controllers/estadisticas_controller.py` | Filtros de fecha, resumen, ranking y serie diaria. |
| `app/controllers/postventa_controller.py` | API de cambios/devoluciones; no tiene una pantalla propia completa. |
| `app/services/__init__.py` | Validadores compartidos de texto, dinero, enteros, booleanos y fechas; excepción NoEncontrado. |
| `app/services/productos_service.py` | Valida campos y combinaciones de la grilla; coordina el repositorio. |
| `app/services/inventario_service.py` | Aplica movimientos, ajusta stock y permite compartir una transacción. |
| `app/services/ventas_service.py` | Valida y registra ventas, pagos, stock, reintentos y anulaciones. |
| `app/services/caja_service.py` | Reglas de apertura/cierre y cálculo de efectivo esperado y diferencia. |
| `app/services/estadisticas_service.py` | Agregados netos de ventas y posventa. |
| `app/services/postventa.py` | Valida devoluciones/cambios, límites y diferencias; coordina stock/caja. |
| `app/repositories/productos_repository.py` | SQL del catálogo/proveedores, grilla transaccional y SKU consecutivo. |
| `static/js/inicio.js` | Eventos, fetch, formularios, imágenes, grilla, carrito, pagos, paginación y gráfico. |
| `static/css/estilos.css` | Apariencia y adaptación de la interfaz a distintos tamaños. |
| `static/assets/logo.png` | Identidad visual de TechFlow. |
| `static/presentacion/contenido.json` | Contenido editable: títulos, diagramas, referencias y notas de las 30 diapositivas. |
| `templates/index.html` | Estructura de las pantallas de gestión y enlace a Presentación. |
| `templates/presentacion.html` | Visor de diapositivas: teclado, índice, notas, pantalla completa e impresión. |
| `run.py` | Arranque de la aplicación principal en el puerto 5000. |
| `run_demo.py` | Arranque en el puerto 5001 con techflow_demo. |
| `requirements.txt` | Dependencias Python: Flask, conector MySQL, dotenv y Pillow. |
| `package.json` | Atajo npm start que ejecuta Python; no implementa backend Node. |
| `.env.example` | Ejemplo de configuración de conexión; no proyectar credenciales reales. |
| `.gitignore` | Exclusiones de cachés, configuración local e imágenes de usuarios. |
| `sql/techflow.sql` | Instalación inicial, 16 tablas, restricciones y datos básicos. |
| `sql/postventa.sql` | Migración aditiva; agrega tablas a la base seleccionada, no una base nueva. |
| `sql/techflow_demo.sql` | Datos ficticios y esquema para una instalación de demostración. |
| `sql/generar_demo.py` | Generador determinista del SQL demo; no conecta con MariaDB. |
| `sql/DEMO.md` | Instrucciones y alcance de la base de ejemplo. |
| `README.md` | Instalación, ejecución y notas generales. |
| `doc/documentacion.md` | Documentación general previa; contrastar con el código actual. |
| `docs/guia-exposicion.md` | Guía técnica anterior, con explicación detallada de normalización. |
| `docs/casos-uso-techflow.puml` | Fuente PlantUML editable de casos de uso. |
| `docs/revision-2026-11-08.md` | Registro histórico de revisión y correcciones. |
| `docs/limpieza-2026-11-10.md` | Decisiones de limpieza y archivos retirados. |
| `docs/notas.txt` | Notas del equipo, conservadas sin atribuirles un contenido no revisado. |

`instance/imagenes_productos/` contiene fotos persistentes, no código. `.git/` contiene el historial. `__pycache__/` y `.pyc` son cachés regenerables. Los modelos sin uso y el servidor Node de ejemplo fueron retirados; no son parte de la arquitectura actual.

## Relación entre materias y evidencias

| Materia | Concepto | Qué mostrar |
|---|---|---|
| Programación | Interfaz por eventos | Botones, grilla y funciones de inicio.js |
| Programación | Bibliotecas / framework | requirements.txt y create_app |
| Programación | Comunicación web | fetch → ruta Flask → JSON |
| Ingeniería | Caso de uso | Registrar venta: precondiciones y alternativas |
| Ingeniería | POO | ProductosService crea ProductosRepository |
| Ingeniería | MVC | mostrarProducto → controlador → servicio → repositorio |
| Base de Datos | Relacional | FK entre productos, variantes y detalle_venta |
| Base de Datos | Normalización | Catálogos separados y excepciones calculadas |
| Base de Datos | Transacciones | cursor_db, commit y rollback |

## Ejemplo SQL para explicar sin modificar datos

```sql
SELECT p.nombre, t.nombre AS talle, c.nombre AS color,
       v.codigo AS sku, v.stock_actual
FROM variantes v
JOIN productos p ON p.id = v.producto_id
JOIN talles t ON t.id = v.talle_id
JOIN colores c ON c.id = v.color_id
ORDER BY p.nombre, t.nombre, c.nombre;
```

Explicar cómo JOIN reúne información sin duplicar nombres en cada tabla. SELECT consulta; INSERT carga; UPDATE modifica. La interfaz desactiva productos para conservar historial en vez de borrar indiscriminadamente.

## Respuestas técnicas ampliadas

**¿Qué forma normal alcanza?** Bajo las reglas actuales, 1FN y 2FN; muchas tablas siguen 3FN, pero no el esquema entero. Revisar claves candidatas, no solo IDs. Subtotal y diferencia de caja son contraejemplos de dependencias entre atributos no clave. El precio histórico es un hecho distinto del precio actual y debe conservarse.

**¿Qué es MVC?** Separación entre presentación, recepción/coordinación de solicitudes y reglas/persistencia. El Modelo no se limita a MariaDB. La implementación es por capas, con servicios y repositorio; algunos servicios contienen SQL y proveedores valida desde el controlador.

**¿Qué es POO?** Organizar comportamiento y estado mediante objetos. Aquí se observan clases, instancias, métodos, colaboración y herencia de excepciones. No se utiliza un modelo de dominio rico ni polimorfismo de negocio desarrollado. Los atributos son públicos; encapsulación de responsabilidades no equivale a privacidad estricta.

**¿Por qué Flask y no todos los frameworks vistos?** Elegimos una solución coherente con Python y una interfaz web sencilla. Tkinter, PHP, React, Vite y Node son conceptos estudiados comparables, no dependencias del producto actual. React es biblioteca, Vite herramienta y Node entorno de ejecución.

**¿Cómo se evita duplicar ventas?** Identificador de solicitud y contenido asociado, transacción y recuperación del resultado en un reintento compatible. El navegador conserva el cobro pendiente; no genera otra venta por perder una respuesta.

**¿Qué pasa con simultaneidad?** Bloqueo de escritura por base y transacciones; esto reduce conflictos a costa de serializar escrituras. No afirmar escalabilidad ilimitada.

**¿Qué no está terminado?** Pantalla de posventa, autenticación/roles, paginación en el servidor y una separación uniforme de capas. La paginación visual actual descarga todos los resultados y muestra 20 por página.

## Diagramas editables

Las fuentes SVG se incluyen en `docs/diagramas/`; pueden insertarse en un documento, imprimirse o abrirse en el navegador. La fuente PlantUML completa de casos de uso está en `docs/casos-uso-techflow.puml`. El contenido de las diapositivas se edita en `static/presentacion/contenido.json`; los diagramas son SVG, no capturas rasterizadas.


## Anexo: herramientas y conceptos vistos en clase

Las materias brindaron herramientas para elegir una solución. Conocer una herramienta no obliga a incluirla como dependencia de la aplicación.

Este anexo es de consulta: puede resumirse durante la exposición o abrirse ante preguntas.

### Python: análisis e interfaces

**pandas.** Organiza, filtra y resume datos en tablas. **En TechFlow:** No se usa; los informes se consultan con SQL.

**matplotlib.** Genera gráficos a partir de datos en Python. **En TechFlow:** No se usa; el gráfico web se dibuja con SVG.

**Tkinter + base de datos.** Crea ventanas de escritorio; sus eventos pueden llamar a un conector SQL. **En TechFlow:** No se usa; elegimos una interfaz en el navegador.

### JavaScript e interfaz web

**HTML, CSS y Flexbox.** HTML estructura; CSS define la apariencia; Flexbox distribuye elementos en una fila o columna. **En TechFlow:** Se usan en la interfaz web.

**Variables, tipos y funciones.** Guardan datos y organizan lógica con condiciones, ciclos y funciones, incluidas las flecha. **En TechFlow:** Sostienen filtros, formularios y cálculos.

**Objetos y listas.** Agrupan datos; copiar, fusionar y desestructurar facilita transformar objetos y arreglos. **En TechFlow:** Se manejan productos, variantes y carrito.

**DOM, eventos y JSON.** El DOM representa la página; los eventos reaccionan a acciones; JSON intercambia datos. **En TechFlow:** JavaScript actualiza la pantalla y conversa con la API.

### Servidores y componentes

**Node.js + Express.** Node ejecuta JavaScript fuera del navegador; Express organiza rutas, respuestas y archivos estáticos. **En TechFlow:** No son el servidor de TechFlow: usamos Flask.

**CRUD y MVC en Node.** CRUD crea, consulta, modifica y elimina; MVC separa responsabilidades. **En TechFlow:** Aplicamos esos conceptos con Python y Flask.

**Asincronismo.** Promesas y async/await permiten esperar operaciones sin bloquear la interacción. **En TechFlow:** Se usan al consultar y guardar mediante la API.

**React + Vite.** React compone interfaces con props y hooks; Vite prepara el entorno de desarrollo y la compilación. **En TechFlow:** No se usan; la interfaz utiliza JavaScript directo.

### Herramientas y abstracciones de datos

**MySQL Server y Workbench.** Server administra datos; Workbench permite modelar un DER y ejecutar SQL para crear el esquema. **En TechFlow:** TechFlow utiliza MariaDB de XAMPP; Workbench no es necesario para ejecutarlo.

**ORM en Python o JavaScript.** Relaciona objetos con tablas y traduce operaciones a consultas. **En TechFlow:** No se usa un ORM: se ejecuta SQL mediante un conector.

**Vistas SQL.** Son consultas guardadas que se consultan como tablas; pueden simplificar el acceso entre capas. **En TechFlow:** El esquema actual no define vistas SQL. No son las vistas de MVC.

**Rendimiento y estrategia.** Claves, índices y planes de consulta ayudan a evaluar búsquedas, relaciones y costos. **En TechFlow:** Hay claves e índices; no se afirma una optimización exhaustiva.

### Diseño, objetos y relaciones

**Diseño y arquitectura.** Definen responsabilidades y cómo colaboran los componentes. **En TechFlow:** La presentación muestra capas, MVC y el recorrido de una solicitud.

**Abstracción y encapsulamiento.** Exponen operaciones y agrupan estado y comportamiento detrás de responsabilidades. **En TechFlow:** Se observan en servicios y repositorios; no implican atributos privados.

**Herencia y polimorfismo.** La herencia especializa tipos; el polimorfismo permite distintas respuestas a una misma operación. **En TechFlow:** Hay herencia de excepciones; no un polimorfismo de negocio desarrollado.

**POO en JavaScript.** Permite organizar comportamiento con objetos, prototipos y clases. **En TechFlow:** La POO del proyecto se explica principalmente con clases Python.

### Relaciones UML y normalización

**Asociación, agregación y composición.** Asociación: vínculo; agregación: todo-parte independiente; composición: propiedad y ciclo de vida ligado. **En TechFlow:** Son herramientas de modelado; no se deducen solo de una clave foránea.

**Interfaz y realización.** Una interfaz define un contrato; la realización expresa que una clase lo implementa. **En TechFlow:** No se presentan como relaciones explícitas implementadas en TechFlow.

**Casos de uso, UML y DER.** Casos de uso describen objetivos; UML modela software; un DER representa entidades y relaciones de datos. **En TechFlow:** Se incluyen los diagramas del proyecto y sus alcances.

**Normalización.** Revisa dependencias para reducir redundancia y anomalías; las formas superiores exigen condiciones adicionales. **En TechFlow:** Se analiza hasta 3FN con excepciones; no se afirma que todo el esquema cumpla 3FN.
