from app.db import cursor_db


class ProductosRepository:
    def listar_productos(self, busqueda="", incluir_inactivos=False):
        sql = """
            SELECT
                p.id,
                p.nombre,
                p.descripcion,
                p.categoria_id,
                p.proveedor_id,
                c.nombre AS categoria,
                p.precio,
                p.activo,
                p.creado_en,
                p.actualizado_en
            FROM productos p
            JOIN categorias c ON c.id = p.categoria_id
            WHERE (
                p.nombre LIKE %s
                OR COALESCE(p.descripcion, '') LIKE %s
            )
        """
        args = [f"%{busqueda}%", f"%{busqueda}%"]

        if not incluir_inactivos:
            sql += " AND p.activo = TRUE"

        sql += " ORDER BY p.nombre, p.id"

        with cursor_db() as (_, cur):
            cur.execute(sql, tuple(args))
            return cur.fetchall()

    def obtener_producto(self, producto_id):
        with cursor_db() as (_, cur):
            cur.execute(
                """
                SELECT
                    p.id,
                    p.nombre,
                    p.descripcion,
                    p.categoria_id,
                p.proveedor_id,
                    c.nombre AS categoria,
                    p.precio,
                    p.activo
                FROM productos p
                JOIN categorias c ON c.id = p.categoria_id
                WHERE p.id = %s
                """,
                (producto_id,),
            )
            return cur.fetchone()

    def crear_producto(self, data):
        with cursor_db(escritura=True) as (_, cur):
            cur.execute(
                """
                INSERT INTO productos (
                    nombre,
                    descripcion,
                    categoria_id,
                    proveedor_id,
                    precio,
                    activo
                )
                VALUES (%s, %s, %s, %s, %s, %s)
                """,
                (
                    data["nombre"],
                    data.get("descripcion"),
                    data["categoria_id"],
                    data.get("proveedor_id"),
                    data["precio"],
                    data.get("activo", True),
                ),
            )
            return cur.lastrowid

    def modificar_producto(self, producto_id, data):
        allowed = {'precio', 'categoria_id', 'activo', 'nombre', 'proveedor_id', 'descripcion'}
        if not data or set(data) - allowed:
            raise ValueError("Campos de actualizacion invalidos.")
        with cursor_db(escritura=True) as (_, cur):
            cur.execute("SELECT id FROM productos WHERE id = %s FOR UPDATE", (producto_id,))
            if not cur.fetchone():
                return False
            assignments = ", ".join(f"{field} = %s" for field in data)
            cur.execute(f"UPDATE productos SET {assignments} WHERE id = %s",
                        (*data.values(), producto_id))
            return True

    def desactivar_producto(self, producto_id):
        return self.modificar_producto(producto_id, {"activo": False})

    def listar_catalogo(self, tabla):
        if tabla not in {"categorias", "talles", "colores"}:
            raise ValueError("Catalogo invalido")

        with cursor_db() as (_, cur):
            cur.execute(
                f"""
                SELECT id, nombre
                FROM {tabla}
                ORDER BY nombre
                """
            )
            return cur.fetchall()

    def crear_catalogo(self, tabla, nombre):
        if tabla not in {"categorias", "talles", "colores"}:
            raise ValueError("Catalogo invalido")

        with cursor_db(escritura=True) as (_, cur):
            cur.execute(
                f"""
                INSERT INTO {tabla} (nombre)
                VALUES (%s)
                """,
                (nombre,),
            )
            return cur.lastrowid

    def listar_variantes(self, producto_id):
        with cursor_db() as (_, cur):
            cur.execute(
                """
                SELECT
                    v.id,
                    v.producto_id,
                    v.talle_id,
                    t.nombre AS talle,
                    v.color_id,
                    c.nombre AS color,
                    v.codigo,
                    v.stock_actual,
                    v.stock_minimo
                FROM variantes v
                JOIN talles t ON t.id = v.talle_id
                JOIN colores c ON c.id = v.color_id
                WHERE v.producto_id = %s
                ORDER BY t.nombre, c.nombre
                """,
                (producto_id,),
            )
            return cur.fetchall()

    def crear_variante(self, data):
        with cursor_db(escritura=True) as (_, cur):
            cur.execute(
                """
                INSERT INTO variantes (
                    producto_id,
                    talle_id,
                    color_id,
                    codigo,
                    stock_minimo
                )
                VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    data["producto_id"],
                    data["talle_id"],
                    data["color_id"],
                    data["codigo"],
                    data.get("stock_minimo", 0),
                ),
            )
            return cur.lastrowid

    def modificar_variante(self, variante_id, data):
        allowed = {'codigo', 'talle_id', 'color_id', 'stock_minimo'}
        if not data or set(data) - allowed:
            raise ValueError("Campos de actualizacion invalidos.")
        with cursor_db(escritura=True) as (_, cur):
            cur.execute("SELECT id FROM variantes WHERE id = %s FOR UPDATE", (variante_id,))
            if not cur.fetchone():
                return False
            assignments = ", ".join(f"{field} = %s" for field in data)
            cur.execute(f"UPDATE variantes SET {assignments} WHERE id = %s",
                        (*data.values(), variante_id))
            return True

    def listar_proveedores(self):
        with cursor_db() as (_, cur):
            cur.execute(
                """
                SELECT id, nombre, telefono, email, direccion, activo
                FROM proveedores
                ORDER BY nombre
                """
            )
            return cur.fetchall()

    def crear_proveedor(self, data):
        with cursor_db(escritura=True) as (_, cur):
            cur.execute(
                """
                INSERT INTO proveedores (
                    nombre,
                    telefono,
                    email,
                    direccion,
                    activo
                )
                VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    data["nombre"],
                    data.get("telefono"),
                    data.get("email"),
                    data.get("direccion"),
                    data.get("activo", True),
                ),
            )
            return cur.lastrowid

    def modificar_proveedor(self, proveedor_id, data):
        allowed = {'activo', 'nombre', 'telefono', 'email', 'direccion'}
        if not data or set(data) - allowed:
            raise ValueError("Campos de actualizacion invalidos.")
        with cursor_db(escritura=True) as (_, cur):
            cur.execute("SELECT id FROM proveedores WHERE id = %s FOR UPDATE", (proveedor_id,))
            if not cur.fetchone():
                return False
            assignments = ", ".join(f"{field} = %s" for field in data)
            cur.execute(f"UPDATE proveedores SET {assignments} WHERE id = %s",
                        (*data.values(), proveedor_id))
            return True
