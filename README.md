# TechFlow Solutions

Proyecto académico de un sistema de gestión para tiendas de ropa.

## Estado actual

Ya funciona una pantalla de bienvenida local desarrollada con
Python y Flask, con el HTML y el CSS separados. El botón «Comprobar servidor»
consulta `/api/estado` usando JavaScript y muestra éxito o error.
Esta comprobación no verifica una conexión a MySQL.

Todavía no están implementados la conexión a MySQL ni los módulos
de productos, inventario, ventas, caja, proveedores y estadísticas.

## Tecnologías

- Python y Flask: servidor local.
- HTML y CSS: contenido y diseño de las pantallas.
- JavaScript: consulta del estado del servidor desde la interfaz.
- MySQL: base de datos, pendiente de conectar.

## Cómo ejecutar el proyecto

### Primera vez

1. Instalar Python, GitHub Desktop y Visual Studio Code.
   La versión inicial fue probada con Python 3.10.9.
2. Clonar este repositorio con GitHub Desktop.
3. Abrir la carpeta del proyecto en VS Code.
4. Abrir Terminal → New Terminal y ejecutar, uno por uno:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

5. En VS Code, usar Python: Select Interpreter y seleccionar
   `.venv\Scripts\python.exe`.

### Iniciar la aplicación

Abrir `run.py` y presionar Run Python File en VS Code.

También se puede ejecutar desde la terminal:

```powershell
.\.venv\Scripts\python.exe run.py
```

Con el servidor encendido, abrir:

http://127.0.0.1:5000

El navegador no se abre automáticamente.
Para detener el servidor, presionar Ctrl + C en la terminal.

Por ahora no hace falta instalar MySQL para ver la bienvenida.

## Organización actual

```text
techflow/
├── app/
│   ├── __init__.py                 # Crea la aplicación
│   ├── controllers/
│   │   ├── __init__.py
│   │   └── inicio_controller.py    # Bienvenida y estado del servidor
│   ├── models/__init__.py          # Futuras clases del dominio
│   ├── repositories/__init__.py    # Futuro acceso a MySQL
│   └── services/__init__.py        # Futuras reglas del negocio
├── templates/index.html           # Pantalla de bienvenida
├── static/
│   ├── css/estilos.css             # Diseño
│   └── js/inicio.js                # Consulta a /api/estado
├── sql/.gitkeep                    # Futuros scripts SQL
├── tests/.gitkeep                  # Futuras pruebas
├── docs/
│   ├── acuerdos-tecnicos.md        # Propuesta para revisar con el equipo
│   └── catedras/.gitkeep           # Futuros materiales académicos
├── run.py                         # Inicia el servidor
├── requirements.txt               # Dependencias
├── .gitignore
├── .env.example                   # Plantilla sin secretos
└── README.md
```

La carpeta `.venv` se crea en cada computadora y no se sube a GitHub.
`.env.example` es una plantilla para la futura conexión: actualmente no se lee.
Los archivos `.gitkeep` permiten registrar carpetas aún vacías.

## Acuerdos técnicos

Leer [la propuesta de rutas, formatos y responsabilidades](docs/acuerdos-tecnicos.md)
antes de construir módulos. Está pendiente de revisión por el equipo.
Solo `/` y `/api/estado` están implementados; el resto son propuestas.

## Comprobación manual

1. Iniciar el servidor, abrir la bienvenida y pulsar «Comprobar servidor».
2. Confirmar el mensaje de éxito.
3. Detener el servidor con Ctrl + C, sin cerrar ni recargar la página.
4. Pulsar el botón y comprobar el mensaje de error.
5. Reiniciar el servidor y repetir: debe volver a mostrar éxito.


## Equipo

- Ezequiel: arquitectura, servidor e integración.
- Maximiliano: base de datos, productos y proveedores.
- Bruno: inventario, ventas y caja.
- Abel: interfaz, estilos y manual de usuario.
- Andrés: estadísticas, reportes y textos académicos.

## Cómo colaborar

1. Actualizar la rama `main` antes de comenzar una tarea.
2. Crear una rama con un nombre que describa el trabajo.
3. Realizar los cambios y probarlos.
4. Crear un commit con un mensaje claro.
5. Subir la rama y abrir un pull request hacia `main`.
6. Pedir revisión a otro integrante antes de integrar los cambios.

No subir contraseñas, archivos `.env` ni la carpeta `.venv`.
Los cambios de tablas o de comunicación entre módulos deben
acordarse con quienes los utilizan.

## Espacios del equipo

- [Repositorio](https://github.com/Nekro3898/techflow)
- [Tablero de tareas](https://techflow-equipo-tablero-ezequiel.dusky-moss-4252.chatgpt.site/board)
- [Página de TechFlow](https://techflow-solutions-coronda.dusky-moss-4252.chatgpt.site)

Exposición: 10 de noviembre de 2026.
