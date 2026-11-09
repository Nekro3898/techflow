-- Datos ficticios: 25/10/2026 al 07/11/2026. No modifica techflow.
-- Ejecutar una sola vez. Si techflow_demo existe, detener la importacion.
CREATE DATABASE techflow_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE techflow_demo;
CREATE TABLE categorias (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    CONSTRAINT chk_cat_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0)
) ENGINE = InnoDB;

CREATE TABLE proveedores (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    telefono VARCHAR(40),
    email VARCHAR(150),
    direccion VARCHAR(255),
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_proveedor_nombre (nombre)
) ENGINE = InnoDB;

CREATE TABLE productos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    categoria_id BIGINT UNSIGNED NOT NULL,
    proveedor_id BIGINT UNSIGNED,
    precio DECIMAL(12, 2) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    KEY ix_prod_cat (categoria_id),
    KEY ix_prod_prov (proveedor_id),
    KEY ix_prod_nombre (nombre),
    CONSTRAINT fk_prod_cat
        FOREIGN KEY (categoria_id)
        REFERENCES categorias (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_prod_prov
        FOREIGN KEY (proveedor_id)
        REFERENCES proveedores (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_prod_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0),
    CONSTRAINT chk_prod_precio CHECK (precio > 0)
) ENGINE = InnoDB;

CREATE TABLE talles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(40) NOT NULL UNIQUE,
    CONSTRAINT chk_talle_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0)
) ENGINE = InnoDB;

CREATE TABLE colores (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL UNIQUE,
    CONSTRAINT chk_color_nombre CHECK (CHAR_LENGTH(TRIM(nombre)) > 0)
) ENGINE = InnoDB;

CREATE TABLE variantes (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    producto_id BIGINT UNSIGNED NOT NULL,
    talle_id BIGINT UNSIGNED NOT NULL,
    color_id BIGINT UNSIGNED NOT NULL,
    codigo VARCHAR(80) NOT NULL UNIQUE,
    stock_actual INT UNSIGNED NOT NULL DEFAULT 0,
    stock_minimo INT UNSIGNED NOT NULL DEFAULT 0,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_variante (producto_id, talle_id, color_id),
    KEY ix_var_prod (producto_id),
    CONSTRAINT fk_var_prod
        FOREIGN KEY (producto_id)
        REFERENCES productos (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_var_talle
        FOREIGN KEY (talle_id)
        REFERENCES talles (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_var_color
        FOREIGN KEY (color_id)
        REFERENCES colores (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_var_codigo CHECK (CHAR_LENGTH(TRIM(codigo)) > 0)
) ENGINE = InnoDB;

CREATE TABLE caja (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fecha_apertura DATETIME NOT NULL,
    fecha_cierre DATETIME,
    saldo_inicial DECIMAL(12, 2) NOT NULL DEFAULT 0,
    efectivo_esperado DECIMAL(12, 2),
    efectivo_contado DECIMAL(12, 2),
    diferencia DECIMAL(12, 2),
    estado ENUM('abierta', 'cerrada') NOT NULL DEFAULT 'abierta',
    CONSTRAINT chk_caja_saldo CHECK (saldo_inicial >= 0)
) ENGINE = InnoDB;

CREATE TABLE ventas (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total DECIMAL(12, 2) NOT NULL,
    medio_pago VARCHAR(30) NOT NULL,
    estado ENUM('completada', 'anulada') NOT NULL DEFAULT 'completada',
    motivo_anulacion VARCHAR(255),
    caja_id BIGINT UNSIGNED NOT NULL,
    solicitud_id VARCHAR(80) NOT NULL UNIQUE,
    KEY ix_ventas_fecha (fecha_hora),
    KEY ix_ventas_caja (caja_id),
    CONSTRAINT fk_venta_caja
        FOREIGN KEY (caja_id)
        REFERENCES caja (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_venta_total CHECK (total >= 0),
    CONSTRAINT chk_venta_medio CHECK (CHAR_LENGTH(TRIM(medio_pago)) > 0)
) ENGINE = InnoDB;

CREATE TABLE detalle_venta (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    venta_id BIGINT UNSIGNED NOT NULL,
    variante_id BIGINT UNSIGNED NOT NULL,
    cantidad INT UNSIGNED NOT NULL,
    precio_unitario DECIMAL(12, 2) NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL,
    KEY ix_det_venta (venta_id),
    KEY ix_det_var (variante_id),
    CONSTRAINT fk_det_venta
        FOREIGN KEY (venta_id)
        REFERENCES ventas (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_det_var
        FOREIGN KEY (variante_id)
        REFERENCES variantes (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_det_cant CHECK (cantidad > 0),
    CONSTRAINT chk_det_precio CHECK (precio_unitario >= 0),
    CONSTRAINT chk_det_sub CHECK (subtotal >= 0)
) ENGINE = InnoDB;

CREATE TABLE pagos_venta (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    venta_id BIGINT UNSIGNED NOT NULL,
    medio ENUM('efectivo', 'transferencia', 'tarjeta') NOT NULL,
    importe DECIMAL(12, 2) NOT NULL,
    KEY ix_pago_venta (venta_id),
    CONSTRAINT fk_pago_venta
        FOREIGN KEY (venta_id)
        REFERENCES ventas (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_pago_importe CHECK (importe > 0)
) ENGINE = InnoDB;

CREATE TABLE solicitudes_venta (
    solicitud_id VARCHAR(80) PRIMARY KEY,
    contenido_hash CHAR(64) NOT NULL,
    estado VARCHAR(20) NOT NULL,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;

CREATE TABLE movimientos_stock (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    variante_id BIGINT UNSIGNED NOT NULL,
    tipo ENUM('ingreso', 'egreso', 'ajuste', 'devolucion') NOT NULL,
    cantidad INT UNSIGNED NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo VARCHAR(255) NOT NULL,
    venta_id BIGINT UNSIGNED,
    KEY ix_mov_var_fecha (variante_id, fecha_hora),
    KEY ix_mov_venta (venta_id),
    CONSTRAINT fk_mov_var
        FOREIGN KEY (variante_id)
        REFERENCES variantes (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_mov_venta
        FOREIGN KEY (venta_id)
        REFERENCES ventas (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_mov_cant CHECK (cantidad > 0),
    CONSTRAINT chk_mov_motivo CHECK (CHAR_LENGTH(TRIM(motivo)) > 0)
) ENGINE = InnoDB;

CREATE TABLE movimientos_caja (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    caja_id BIGINT UNSIGNED NOT NULL,
    tipo ENUM('ingreso', 'venta', 'retiro') NOT NULL,
    importe DECIMAL(12, 2) NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    referencia VARCHAR(255),
    KEY ix_mov_caja (caja_id),
    CONSTRAINT fk_mov_caja
        FOREIGN KEY (caja_id)
        REFERENCES caja (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_mov_caja_importe CHECK (importe >= 0)
) ENGINE = InnoDB;

-- Ejecutar sobre la base seleccionada (techflow o techflow_demo).
-- Migracion aditiva: no elimina ni modifica registros existentes.

CREATE TABLE IF NOT EXISTS devoluciones (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    venta_id BIGINT UNSIGNED NOT NULL,
    tipo ENUM('cambio', 'devolucion') NOT NULL,
    motivo VARCHAR(255) NOT NULL,
    total_diferencia DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY ix_devolucion_venta (venta_id),
    CONSTRAINT fk_devolucion_venta
        FOREIGN KEY (venta_id)
        REFERENCES ventas (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_devolucion_motivo CHECK (CHAR_LENGTH(TRIM(motivo)) > 0)
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS detalle_devolucion (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    devolucion_id BIGINT UNSIGNED NOT NULL,
    variante_id BIGINT UNSIGNED NOT NULL,
    detalle_venta_id BIGINT UNSIGNED,
    direccion ENUM('devuelto', 'nuevo') NOT NULL,
    cantidad INT UNSIGNED NOT NULL,
    precio_unitario DECIMAL(12, 2) NOT NULL,
    KEY ix_detdev_operacion (devolucion_id),
    KEY ix_detdev_origen (detalle_venta_id),
    CONSTRAINT fk_detdev_operacion FOREIGN KEY (devolucion_id) REFERENCES devoluciones(id) ON DELETE RESTRICT,
    CONSTRAINT fk_detdev_variante FOREIGN KEY (variante_id) REFERENCES variantes(id) ON DELETE RESTRICT,
    CONSTRAINT fk_detdev_origen FOREIGN KEY (detalle_venta_id) REFERENCES detalle_venta(id) ON DELETE RESTRICT,
    CONSTRAINT chk_detdev_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_detdev_precio CHECK (precio_unitario >= 0),
    CONSTRAINT chk_detdev_origen CHECK ((direccion = 'devuelto' AND detalle_venta_id IS NOT NULL)
                                      OR (direccion = 'nuevo' AND detalle_venta_id IS NULL))
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS solicitudes_postventa (
    solicitud_id VARCHAR(80) PRIMARY KEY,
    contenido_hash CHAR(64) NOT NULL,
    devolucion_id BIGINT UNSIGNED NOT NULL UNIQUE,
    caja_id BIGINT UNSIGNED NOT NULL,
    medio_pago ENUM('efectivo', 'tarjeta', 'transferencia') NOT NULL,
    creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_solpost_devolucion FOREIGN KEY (devolucion_id) REFERENCES devoluciones(id) ON DELETE RESTRICT,
    CONSTRAINT fk_solpost_caja FOREIGN KEY (caja_id) REFERENCES caja(id) ON DELETE RESTRICT
) ENGINE = InnoDB;


START TRANSACTION;
INSERT INTO categorias (id, nombre) VALUES (1, 'Remeras');
INSERT INTO categorias (id, nombre) VALUES (2, 'Pantalones');
INSERT INTO categorias (id, nombre) VALUES (3, 'Abrigos');
INSERT INTO categorias (id, nombre) VALUES (4, 'Camisas');
INSERT INTO proveedores (id, nombre, telefono, email, direccion, creado_en) VALUES (1, 'Textiles del Litoral', '0342-555-0101', 'proveedor1@example.com', 'Calle de ejemplo 100', '2026-10-25 08:00:00');
INSERT INTO proveedores (id, nombre, telefono, email, direccion, creado_en) VALUES (2, 'Denim Centro', '0342-555-0102', 'proveedor2@example.com', 'Calle de ejemplo 200', '2026-10-25 08:00:00');
INSERT INTO proveedores (id, nombre, telefono, email, direccion, creado_en) VALUES (3, 'Moda Coronda', '0342-555-0103', 'proveedor3@example.com', 'Calle de ejemplo 300', '2026-10-25 08:00:00');
INSERT INTO talles (id, nombre) VALUES (1, 'S');
INSERT INTO talles (id, nombre) VALUES (2, 'M');
INSERT INTO talles (id, nombre) VALUES (3, 'L');
INSERT INTO talles (id, nombre) VALUES (4, 'XL');
INSERT INTO colores (id, nombre) VALUES (1, 'Negro');
INSERT INTO colores (id, nombre) VALUES (2, 'Blanco');
INSERT INTO colores (id, nombre) VALUES (3, 'Azul');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (1, 'Remera basica', 'Producto ficticio para demostracion', 1, 1, 15000, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (1, 1, 1, 1, 'DEMO-01-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (1, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (2, 1, 2, 2, 'DEMO-01-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (2, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (3, 1, 3, 3, 'DEMO-01-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (3, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (4, 1, 4, 1, 'DEMO-01-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (4, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (2, 'Remera estampada', 'Producto ficticio para demostracion', 1, 2, 18500, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (5, 2, 1, 1, 'DEMO-02-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (5, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (6, 2, 2, 2, 'DEMO-02-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (6, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (7, 2, 3, 3, 'DEMO-02-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (7, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (8, 2, 4, 1, 'DEMO-02-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (8, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (3, 'Remera oversize', 'Producto ficticio para demostracion', 1, 3, 22000, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (9, 3, 1, 1, 'DEMO-03-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (9, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (10, 3, 2, 2, 'DEMO-03-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (10, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (11, 3, 3, 3, 'DEMO-03-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (11, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (12, 3, 4, 1, 'DEMO-03-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (12, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (4, 'Jean recto', 'Producto ficticio para demostracion', 2, 1, 32000, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (13, 4, 1, 1, 'DEMO-04-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (13, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (14, 4, 2, 2, 'DEMO-04-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (14, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (15, 4, 3, 3, 'DEMO-04-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (15, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (16, 4, 4, 1, 'DEMO-04-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (16, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (5, 'Jean elastizado', 'Producto ficticio para demostracion', 2, 2, 36000, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (17, 5, 1, 1, 'DEMO-05-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (17, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (18, 5, 2, 2, 'DEMO-05-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (18, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (19, 5, 3, 3, 'DEMO-05-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (19, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (20, 5, 4, 1, 'DEMO-05-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (20, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (6, 'Pantalon cargo', 'Producto ficticio para demostracion', 2, 3, 42000, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (21, 6, 1, 1, 'DEMO-06-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (21, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (22, 6, 2, 2, 'DEMO-06-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (22, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (23, 6, 3, 3, 'DEMO-06-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (23, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (24, 6, 4, 1, 'DEMO-06-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (24, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (7, 'Buzo liviano', 'Producto ficticio para demostracion', 3, 1, 28000, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (25, 7, 1, 1, 'DEMO-07-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (25, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (26, 7, 2, 2, 'DEMO-07-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (26, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (27, 7, 3, 3, 'DEMO-07-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (27, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (28, 7, 4, 1, 'DEMO-07-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (28, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (8, 'Buzo con capucha', 'Producto ficticio para demostracion', 3, 2, 38500, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (29, 8, 1, 1, 'DEMO-08-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (29, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (30, 8, 2, 2, 'DEMO-08-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (30, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (31, 8, 3, 3, 'DEMO-08-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (31, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (32, 8, 4, 1, 'DEMO-08-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (32, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (9, 'Campera de jean', 'Producto ficticio para demostracion', 3, 3, 65000, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (33, 9, 1, 1, 'DEMO-09-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (33, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (34, 9, 2, 2, 'DEMO-09-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (34, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (35, 9, 3, 3, 'DEMO-09-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (35, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (36, 9, 4, 1, 'DEMO-09-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (36, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (10, 'Camisa de lino', 'Producto ficticio para demostracion', 4, 1, 34000, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (37, 10, 1, 1, 'DEMO-10-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (37, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (38, 10, 2, 2, 'DEMO-10-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (38, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (39, 10, 3, 3, 'DEMO-10-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (39, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (40, 10, 4, 1, 'DEMO-10-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (40, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (11, 'Camisa a cuadros', 'Producto ficticio para demostracion', 4, 2, 29500, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (41, 11, 1, 1, 'DEMO-11-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (41, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (42, 11, 2, 2, 'DEMO-11-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (42, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (43, 11, 3, 3, 'DEMO-11-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (43, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (44, 11, 4, 1, 'DEMO-11-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (44, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO productos (id, nombre, descripcion, categoria_id, proveedor_id, precio, activo, creado_en, actualizado_en) VALUES (12, 'Camisa clasica', 'Producto ficticio para demostracion', 4, 3, 31000, 1, '2026-10-25 08:00:00', '2026-10-25 08:00:00');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (45, 12, 1, 1, 'DEMO-12-1', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (45, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (46, 12, 2, 2, 'DEMO-12-2', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (46, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (47, 12, 3, 3, 'DEMO-12-3', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (47, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO variantes (id, producto_id, talle_id, color_id, codigo, stock_actual, stock_minimo, creado_en) VALUES (48, 12, 4, 1, 'DEMO-12-4', 0, 3, '2026-10-25 08:00:00');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (48, 'ingreso', 12, '2026-10-25 08:00:00', 'Recepcion inicial de mercaderia demo');
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (1, '2026-10-25 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (1, '2026-10-25 09:30:00', 22000, 'efectivo', 'completada', NULL, 1, 'demo-20261025-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261025-001', 'cf17c32b155b83b1be2d2a46ae1b2b4a91064424c5776acd82f2f367d5e89d4a', 'creada', '2026-10-25 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (1, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-10-25 09:30:00', 'Venta #1', 1);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (1, 'efectivo', 22000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (1, 'venta', 22000, '2026-10-25 09:30:00', 'Venta #1');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (2, '2026-10-25 10:15:00', 192000, 'transferencia', 'completada', NULL, 1, 'demo-20261025-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261025-002', '834be75cc046985cbfb06a6dbdb00c388f60085bfce2d1378eb48a6456ec8241', 'creada', '2026-10-25 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (2, 34, 2, 65000, 130000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (34, 'egreso', 2, '2026-10-25 10:15:00', 'Venta #2', 2);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (2, 48, 2, 31000, 62000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (48, 'egreso', 2, '2026-10-25 10:15:00', 'Venta #2', 2);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (2, 'transferencia', 192000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (1, 'venta', 0, '2026-10-25 10:15:00', 'Venta #2');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (3, '2026-10-25 11:00:00', 104000, 'tarjeta', 'completada', NULL, 1, 'demo-20261025-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261025-003', '2e2a80db9f97839e63c15f2f229cd91849eab88435cf4dccba46bba370c7b6eb', 'creada', '2026-10-25 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (3, 1, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 2, '2026-10-25 11:00:00', 'Venta #3', 3);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (3, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-10-25 11:00:00', 'Venta #3', 3);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (3, 10, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (10, 'egreso', 2, '2026-10-25 11:00:00', 'Venta #3', 3);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (3, 'tarjeta', 104000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (1, 'venta', 0, '2026-10-25 11:00:00', 'Venta #3');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (4, '2026-10-25 11:45:00', 28000, 'mixto', 'completada', NULL, 1, 'demo-20261025-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261025-004', 'c6af74cc9b7d613ebdb4e0a9b8bb1b0609ca1af6f4829ba9b4dd43eb32fa76e9', 'creada', '2026-10-25 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (4, 25, 1, 28000, 28000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (25, 'egreso', 1, '2026-10-25 11:45:00', 'Venta #4', 4);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (4, 'efectivo', 14000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (4, 'tarjeta', 14000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (1, 'venta', 14000, '2026-10-25 11:45:00', 'Venta #4');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (5, '2026-10-25 12:30:00', 59000, 'efectivo', 'completada', NULL, 1, 'demo-20261025-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261025-005', '29997b76f25fe675c55419bbda9abedfe81f9dd5ef84cd23f8d8c5b1db8b6759', 'creada', '2026-10-25 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (5, 11, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (11, 'egreso', 1, '2026-10-25 12:30:00', 'Venta #5', 5);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (5, 8, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'egreso', 2, '2026-10-25 12:30:00', 'Venta #5', 5);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (5, 'efectivo', 59000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (1, 'venta', 59000, '2026-10-25 12:30:00', 'Venta #5');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (6, '2026-10-25 13:15:00', 117500, 'transferencia', 'completada', NULL, 1, 'demo-20261025-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261025-006', '8758e6d64d89ce6536fb39f27c517c0015c559a58570ed5e1950624fd1020428', 'creada', '2026-10-25 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (6, 30, 2, 38500, 77000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (30, 'egreso', 2, '2026-10-25 13:15:00', 'Venta #6', 6);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (6, 7, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (7, 'egreso', 1, '2026-10-25 13:15:00', 'Venta #6', 6);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (6, 11, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (11, 'egreso', 1, '2026-10-25 13:15:00', 'Venta #6', 6);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (6, 'transferencia', 117500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (1, 'venta', 0, '2026-10-25 13:15:00', 'Venta #6');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (7, '2026-10-25 14:00:00', 15000, 'tarjeta', 'completada', NULL, 1, 'demo-20261025-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261025-007', '68f8c5dcc69c42a9052919ec121812de2fc7615eb05c56c9b83d760af451f165', 'creada', '2026-10-25 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (7, 3, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (3, 'egreso', 1, '2026-10-25 14:00:00', 'Venta #7', 7);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (7, 'tarjeta', 15000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (1, 'venta', 0, '2026-10-25 14:00:00', 'Venta #7');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (8, '2026-10-25 14:45:00', 103000, 'mixto', 'completada', NULL, 1, 'demo-20261025-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261025-008', '2a6fa5d073fce9f5a538ed61d31f0afaa268b7898b1dc866d64e39693feb514c', 'creada', '2026-10-25 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (8, 19, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (19, 'egreso', 2, '2026-10-25 14:45:00', 'Venta #8', 8);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (8, 47, 1, 31000, 31000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (47, 'egreso', 1, '2026-10-25 14:45:00', 'Venta #8', 8);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (8, 'efectivo', 51500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (8, 'tarjeta', 51500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (1, 'venta', 51500, '2026-10-25 14:45:00', 'Venta #8');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (1, 'retiro', 136500, '2026-10-25 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-10-25 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=1;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (2, '2026-10-26 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (9, '2026-10-26 09:30:00', 22000, 'efectivo', 'completada', NULL, 2, 'demo-20261026-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261026-001', '68844ac9eb40c4498aa77bee3d1933379577bd02a7a20097f32f8c3db219e7bf', 'creada', '2026-10-26 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (9, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-10-26 09:30:00', 'Venta #9', 9);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (9, 'efectivo', 22000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (2, 'venta', 22000, '2026-10-26 09:30:00', 'Venta #9');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (10, '2026-10-26 10:15:00', 124000, 'transferencia', 'completada', NULL, 2, 'demo-20261026-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261026-002', '38aa1c83ef3b5b0246926bf90eca85c893640299ea9c39334475095e0ccd2a89', 'creada', '2026-10-26 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (10, 28, 2, 28000, 56000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (28, 'egreso', 2, '2026-10-26 10:15:00', 'Venta #10', 10);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (10, 40, 2, 34000, 68000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (40, 'egreso', 2, '2026-10-26 10:15:00', 'Venta #10', 10);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (10, 'transferencia', 124000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (2, 'venta', 0, '2026-10-26 10:15:00', 'Venta #10');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (11, '2026-10-26 11:00:00', 75000, 'tarjeta', 'completada', NULL, 2, 'demo-20261026-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261026-003', 'cbd201f1fbc69e45eedf2212976e1e94502c1e0514ee8b39eb9e9bd1f2893209', 'creada', '2026-10-26 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (11, 1, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 2, '2026-10-26 11:00:00', 'Venta #11', 11);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (11, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-10-26 11:00:00', 'Venta #11', 11);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (11, 4, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (4, 'egreso', 1, '2026-10-26 11:00:00', 'Venta #11', 11);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (11, 'tarjeta', 75000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (2, 'venta', 0, '2026-10-26 11:00:00', 'Venta #11');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (12, '2026-10-26 11:45:00', 72000, 'mixto', 'completada', NULL, 2, 'demo-20261026-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261026-004', 'd9c8431f6671a753ce7e30e3c8e461f0f93fdf01e72079d517fe40015854394d', 'creada', '2026-10-26 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (12, 19, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (19, 'egreso', 2, '2026-10-26 11:45:00', 'Venta #12', 12);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (12, 'efectivo', 36000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (12, 'tarjeta', 36000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (2, 'venta', 36000, '2026-10-26 11:45:00', 'Venta #12');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (13, '2026-10-26 12:30:00', 66000, 'efectivo', 'completada', NULL, 2, 'demo-20261026-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261026-005', 'fca84df0c890bbdd5e435142e14e87662081ea50c8e1ef66401163c09cc79ed7', 'creada', '2026-10-26 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (13, 10, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (10, 'egreso', 1, '2026-10-26 12:30:00', 'Venta #13', 13);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (13, 11, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (11, 'egreso', 2, '2026-10-26 12:30:00', 'Venta #13', 13);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (13, 'efectivo', 66000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (2, 'venta', 66000, '2026-10-26 12:30:00', 'Venta #13');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (14, '2026-10-26 13:15:00', 157000, 'transferencia', 'completada', NULL, 2, 'demo-20261026-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261026-006', 'edf926c2ba8a641964f2833b372800baf3a186b994de01c1155a78918ce0ed2f', 'creada', '2026-10-26 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (14, 20, 1, 36000, 36000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (20, 'egreso', 1, '2026-10-26 13:15:00', 'Venta #14', 14);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (14, 35, 1, 65000, 65000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (35, 'egreso', 1, '2026-10-26 13:15:00', 'Venta #14', 14);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (14, 28, 2, 28000, 56000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (28, 'egreso', 2, '2026-10-26 13:15:00', 'Venta #14', 14);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (14, 'transferencia', 157000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (2, 'venta', 0, '2026-10-26 13:15:00', 'Venta #14');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (15, '2026-10-26 14:00:00', 30000, 'tarjeta', 'completada', NULL, 2, 'demo-20261026-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261026-007', 'fd0333949154136149cd51029a222fc56ec6b376ccbc44a2493836e0ac6da6f0', 'creada', '2026-10-26 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (15, 3, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (3, 'egreso', 2, '2026-10-26 14:00:00', 'Venta #15', 15);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (15, 'tarjeta', 30000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (2, 'venta', 0, '2026-10-26 14:00:00', 'Venta #15');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (16, '2026-10-26 14:45:00', 103000, 'mixto', 'completada', NULL, 2, 'demo-20261026-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261026-008', 'f6fcb1f0900afc48d73ec3f17afbdbaed564af764ffab510c658cfc0f9986610', 'creada', '2026-10-26 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (16, 47, 1, 31000, 31000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (47, 'egreso', 1, '2026-10-26 14:45:00', 'Venta #16', 16);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (16, 20, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (20, 'egreso', 2, '2026-10-26 14:45:00', 'Venta #16', 16);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (16, 'efectivo', 51500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (16, 'tarjeta', 51500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (2, 'venta', 51500, '2026-10-26 14:45:00', 'Venta #16');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (17, '2026-10-26 15:30:00', 85500, 'efectivo', 'completada', NULL, 2, 'demo-20261026-009');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261026-009', '8b8382225cb15d6f472d7324c35453884c2c89da67676dd42b4e316f29fec2ec', 'creada', '2026-10-26 15:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (17, 5, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 2, '2026-10-26 15:30:00', 'Venta #17', 17);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (17, 7, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (7, 'egreso', 1, '2026-10-26 15:30:00', 'Venta #17', 17);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (17, 3, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (3, 'egreso', 2, '2026-10-26 15:30:00', 'Venta #17', 17);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (17, 'efectivo', 85500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (2, 'venta', 85500, '2026-10-26 15:30:00', 'Venta #17');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (2, 'retiro', 251000, '2026-10-26 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-10-26 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=2;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (3, '2026-10-27 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (18, '2026-10-27 09:30:00', 15000, 'efectivo', 'completada', NULL, 3, 'demo-20261027-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261027-001', 'aa3dbb8ca87c8216bb131351aa2eebc73e12a38d76e2c39363a9bb904af34bc2', 'creada', '2026-10-27 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (18, 1, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 1, '2026-10-27 09:30:00', 'Venta #18', 18);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (18, 'efectivo', 15000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'venta', 15000, '2026-10-27 09:30:00', 'Venta #18');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (19, '2026-10-27 10:15:00', 51500, 'transferencia', 'completada', NULL, 3, 'demo-20261027-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261027-002', 'ea9d4adce95dc4a8576c38763c1dc71ae171a3f61c5acfc74249fc5c14b29043', 'creada', '2026-10-27 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (19, 12, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (12, 'egreso', 1, '2026-10-27 10:15:00', 'Venta #19', 19);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (19, 44, 1, 29500, 29500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (44, 'egreso', 1, '2026-10-27 10:15:00', 'Venta #19', 19);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (19, 'transferencia', 51500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'venta', 0, '2026-10-27 10:15:00', 'Venta #19');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (20, '2026-10-27 11:00:00', 96000, 'tarjeta', 'anulada', 'Cliente cancelo la compra', 3, 'demo-20261027-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261027-003', '3a3ce0418c74c738e322c7d86df83b9a2db7391a1a847ff0b7cf00b27bbdc285', 'creada', '2026-10-27 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (20, 10, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (10, 'egreso', 1, '2026-10-27 11:00:00', 'Venta #20', 20);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (10, 'devolucion', 1, '2026-10-27 11:15:00', 'Cliente cancelo la compra', 20);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (20, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-10-27 11:00:00', 'Venta #20', 20);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'devolucion', 2, '2026-10-27 11:15:00', 'Cliente cancelo la compra', 20);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (20, 9, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 2, '2026-10-27 11:00:00', 'Venta #20', 20);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'devolucion', 2, '2026-10-27 11:15:00', 'Cliente cancelo la compra', 20);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (20, 'tarjeta', 96000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'venta', 0, '2026-10-27 11:00:00', 'Venta #20');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (21, '2026-10-27 11:45:00', 77000, 'mixto', 'completada', NULL, 3, 'demo-20261027-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261027-004', '1708173e8ea1629bd6153d96735523aba0bdf42d2f5a4ad2ea7ca8e8773f2545', 'creada', '2026-10-27 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (21, 30, 2, 38500, 77000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (30, 'egreso', 2, '2026-10-27 11:45:00', 'Venta #21', 21);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (21, 'efectivo', 38500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (21, 'tarjeta', 38500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'venta', 38500, '2026-10-27 11:45:00', 'Venta #21');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (22, '2026-10-27 12:30:00', 33500, 'efectivo', 'completada', NULL, 3, 'demo-20261027-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261027-005', 'b9cd0b1318207b827673b43118e9aa65c802f68e337ccf776850cb641efc4c56', 'creada', '2026-10-27 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (22, 6, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (6, 'egreso', 1, '2026-10-27 12:30:00', 'Venta #22', 22);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (22, 3, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (3, 'egreso', 1, '2026-10-27 12:30:00', 'Venta #22', 22);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (22, 'efectivo', 33500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'venta', 33500, '2026-10-27 12:30:00', 'Venta #22');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (23, '2026-10-27 13:15:00', 120000, 'transferencia', 'completada', NULL, 3, 'demo-20261027-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261027-006', 'c8e75f8f28e78b5a0ec63558a2cda85f37a881274c0f1f4f5c2f37854100cf46', 'creada', '2026-10-27 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (23, 42, 1, 29500, 29500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (42, 'egreso', 1, '2026-10-27 13:15:00', 'Venta #23', 23);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (23, 6, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (6, 'egreso', 1, '2026-10-27 13:15:00', 'Venta #23', 23);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (23, 19, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (19, 'egreso', 2, '2026-10-27 13:15:00', 'Venta #23', 23);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (23, 'transferencia', 120000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'venta', 0, '2026-10-27 13:15:00', 'Venta #23');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (24, '2026-10-27 14:00:00', 44000, 'tarjeta', 'completada', NULL, 3, 'demo-20261027-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261027-007', '730f73580f0ab820dabd6c27ca4297c951c9aa7c1a1374ed96405b504e012244', 'creada', '2026-10-27 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (24, 11, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (11, 'egreso', 2, '2026-10-27 14:00:00', 'Venta #24', 24);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (24, 'tarjeta', 44000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'venta', 0, '2026-10-27 14:00:00', 'Venta #24');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (25, '2026-10-27 14:45:00', 100000, 'mixto', 'completada', NULL, 3, 'demo-20261027-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261027-008', '153c8bdf3e1b7f1d2050c7da7054b383d0edb61b60dd0cd084e1d04b2325aa4f', 'creada', '2026-10-27 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (25, 25, 1, 28000, 28000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (25, 'egreso', 1, '2026-10-27 14:45:00', 'Venta #25', 25);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (25, 17, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (17, 'egreso', 2, '2026-10-27 14:45:00', 'Venta #25', 25);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (25, 'efectivo', 50000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (25, 'tarjeta', 50000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'venta', 50000, '2026-10-27 14:45:00', 'Venta #25');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (26, '2026-10-27 15:30:00', 77500, 'efectivo', 'completada', NULL, 3, 'demo-20261027-009');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261027-009', 'a39d2c92c6a30928bf255c2734dfe13d5f7bcad647609092a31950bfa7bb51c5', 'creada', '2026-10-27 15:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (26, 7, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (7, 'egreso', 1, '2026-10-27 15:30:00', 'Venta #26', 26);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (26, 6, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (6, 'egreso', 2, '2026-10-27 15:30:00', 'Venta #26', 26);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (26, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-10-27 15:30:00', 'Venta #26', 26);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (26, 'efectivo', 77500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'venta', 77500, '2026-10-27 15:30:00', 'Venta #26');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (27, '2026-10-27 16:15:00', 29500, 'transferencia', 'completada', NULL, 3, 'demo-20261027-010');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261027-010', '20fb78a7a5163ccf8d7ad1c66842e1a96336cb2734cdd22eb88959fb129073ad', 'creada', '2026-10-27 16:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (27, 42, 1, 29500, 29500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (42, 'egreso', 1, '2026-10-27 16:15:00', 'Venta #27', 27);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (27, 'transferencia', 29500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'venta', 0, '2026-10-27 16:15:00', 'Venta #27');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (3, 'retiro', 204500, '2026-10-27 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-10-27 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=3;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (4, '2026-10-28 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (28, '2026-10-28 09:30:00', 22000, 'efectivo', 'completada', NULL, 4, 'demo-20261028-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-001', '8dc60e45ed184a99a56b3958958b93812628c3220fbc0a902bdfca9b1cdaf00c', 'creada', '2026-10-28 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (28, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-10-28 09:30:00', 'Venta #28', 28);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (28, 'efectivo', 22000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 22000, '2026-10-28 09:30:00', 'Venta #28');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (29, '2026-10-28 10:15:00', 121000, 'transferencia', 'completada', NULL, 4, 'demo-20261028-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-002', 'e94d370d59cbd5a88b1401e4a4fe3bc64b307bf5f73aceb52323a7db0d8fb61f', 'creada', '2026-10-28 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (29, 46, 2, 31000, 62000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (46, 'egreso', 2, '2026-10-28 10:15:00', 'Venta #29', 29);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (29, 41, 2, 29500, 59000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (41, 'egreso', 2, '2026-10-28 10:15:00', 'Venta #29', 29);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (29, 'transferencia', 121000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 0, '2026-10-28 10:15:00', 'Venta #29');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (30, '2026-10-28 11:00:00', 104000, 'tarjeta', 'completada', NULL, 4, 'demo-20261028-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-003', 'fe9c733f1baf120fa726582bc76481b9aa38169c2857a004b5b01c4e2f37f9ac', 'creada', '2026-10-28 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (30, 3, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (3, 'egreso', 2, '2026-10-28 11:00:00', 'Venta #30', 30);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (30, 11, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (11, 'egreso', 2, '2026-10-28 11:00:00', 'Venta #30', 30);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (30, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-10-28 11:00:00', 'Venta #30', 30);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (30, 'tarjeta', 104000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 0, '2026-10-28 11:00:00', 'Venta #30');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (31, '2026-10-28 11:45:00', 64000, 'mixto', 'completada', NULL, 4, 'demo-20261028-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-004', '1d8a952728a521c3b1346eccdd335be3d1d47d3b9c6a0f3103a6ab520566237a', 'creada', '2026-10-28 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (31, 14, 2, 32000, 64000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (14, 'egreso', 2, '2026-10-28 11:45:00', 'Venta #31', 31);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (31, 'efectivo', 32000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (31, 'tarjeta', 32000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 32000, '2026-10-28 11:45:00', 'Venta #31');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (32, '2026-10-28 12:30:00', 67000, 'efectivo', 'completada', NULL, 4, 'demo-20261028-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-005', 'bab46c367bb428568c9b84bed1603b0605d58e2bae53c10266e5e46f5e69b307', 'creada', '2026-10-28 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (32, 6, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (6, 'egreso', 2, '2026-10-28 12:30:00', 'Venta #32', 32);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (32, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-10-28 12:30:00', 'Venta #32', 32);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (32, 'efectivo', 67000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 67000, '2026-10-28 12:30:00', 'Venta #32');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (33, '2026-10-28 13:15:00', 126500, 'transferencia', 'completada', NULL, 4, 'demo-20261028-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-006', 'dc7c9b0fe64715192e8f09731988ee2b163e1e0ac808086a2ed5d3afd8066d3c', 'creada', '2026-10-28 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (33, 8, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'egreso', 1, '2026-10-28 13:15:00', 'Venta #33', 33);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (33, 12, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (12, 'egreso', 2, '2026-10-28 13:15:00', 'Venta #33', 33);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (33, 16, 2, 32000, 64000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (16, 'egreso', 2, '2026-10-28 13:15:00', 'Venta #33', 33);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (33, 'transferencia', 126500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 0, '2026-10-28 13:15:00', 'Venta #33');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (34, '2026-10-28 14:00:00', 18500, 'tarjeta', 'completada', NULL, 4, 'demo-20261028-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-007', 'cbb4503f42bffec9a626d6d6f5f3148f72f6cd501d5b859667dff5454bd7924a', 'creada', '2026-10-28 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (34, 6, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (6, 'egreso', 1, '2026-10-28 14:00:00', 'Venta #34', 34);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (34, 'tarjeta', 18500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 0, '2026-10-28 14:00:00', 'Venta #34');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (35, '2026-10-28 14:45:00', 99000, 'mixto', 'completada', NULL, 4, 'demo-20261028-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-008', '4046e7310f7e3758a24964c22663a9a459902b7d2ecbcc2d218acde7302786ee', 'creada', '2026-10-28 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (35, 29, 2, 38500, 77000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (29, 'egreso', 2, '2026-10-28 14:45:00', 'Venta #35', 35);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (35, 12, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (12, 'egreso', 1, '2026-10-28 14:45:00', 'Venta #35', 35);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (35, 'efectivo', 49500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (35, 'tarjeta', 49500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 49500, '2026-10-28 14:45:00', 'Venta #35');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (36, '2026-10-28 15:30:00', 77500, 'efectivo', 'completada', NULL, 4, 'demo-20261028-009');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-009', '516cba2369910e71cb7cf36738d6dc39d185dbe6563c127f67123b219ba14639', 'creada', '2026-10-28 15:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (36, 5, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 1, '2026-10-28 15:30:00', 'Venta #36', 36);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (36, 7, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (7, 'egreso', 2, '2026-10-28 15:30:00', 'Venta #36', 36);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (36, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-10-28 15:30:00', 'Venta #36', 36);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (36, 'efectivo', 77500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 77500, '2026-10-28 15:30:00', 'Venta #36');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (37, '2026-10-28 16:15:00', 62000, 'transferencia', 'completada', NULL, 4, 'demo-20261028-010');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-010', '8ecf2b840a9da82ee1d1c2c8d7dcf8e7131273aee53b13a87835ff4dc6cf956a', 'creada', '2026-10-28 16:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (37, 45, 2, 31000, 62000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (45, 'egreso', 2, '2026-10-28 16:15:00', 'Venta #37', 37);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (37, 'transferencia', 62000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 0, '2026-10-28 16:15:00', 'Venta #37');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (38, '2026-10-28 17:00:00', 74000, 'tarjeta', 'completada', NULL, 4, 'demo-20261028-011');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261028-011', '8d00ba1263fa2a0dcb1b6fbba3599357583d3c09eb9b9db01ab098eceedce416', 'creada', '2026-10-28 17:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (38, 12, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (12, 'egreso', 2, '2026-10-28 17:00:00', 'Venta #38', 38);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (38, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-10-28 17:00:00', 'Venta #38', 38);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (38, 'tarjeta', 74000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'venta', 0, '2026-10-28 17:00:00', 'Venta #38');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (4, 'retiro', 238000, '2026-10-28 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-10-28 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=4;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (5, '2026-10-29 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (39, '2026-10-29 09:30:00', 44000, 'efectivo', 'completada', NULL, 5, 'demo-20261029-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261029-001', '0222ee6ed27e94332655fbe86c4e4335d51a1a5d952d8051cda920fd363e517d', 'creada', '2026-10-29 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (39, 10, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (10, 'egreso', 2, '2026-10-29 09:30:00', 'Venta #39', 39);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (39, 'efectivo', 44000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (5, 'venta', 44000, '2026-10-29 09:30:00', 'Venta #39');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (40, '2026-10-29 10:15:00', 77500, 'transferencia', 'completada', NULL, 5, 'demo-20261029-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261029-002', 'c9e372822ff4ae506219797a9af1bcb3694230b1d0c75607a2ec77131df741c5', 'creada', '2026-10-29 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (40, 5, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 1, '2026-10-29 10:15:00', 'Venta #40', 40);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (40, 44, 2, 29500, 59000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (44, 'egreso', 2, '2026-10-29 10:15:00', 'Venta #40', 40);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (40, 'transferencia', 77500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (5, 'venta', 0, '2026-10-29 10:15:00', 'Venta #40');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (41, '2026-10-29 11:00:00', 82000, 'tarjeta', 'completada', NULL, 5, 'demo-20261029-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261029-003', '62eff91953a7c651b0991ba899b4812322d2eb212d6c92f0d240d2fc1b3a8d71', 'creada', '2026-10-29 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (41, 4, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (4, 'egreso', 2, '2026-10-29 11:00:00', 'Venta #41', 41);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (41, 1, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 2, '2026-10-29 11:00:00', 'Venta #41', 41);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (41, 11, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (11, 'egreso', 1, '2026-10-29 11:00:00', 'Venta #41', 41);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (41, 'tarjeta', 82000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (5, 'venta', 0, '2026-10-29 11:00:00', 'Venta #41');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (42, '2026-10-29 11:45:00', 64000, 'mixto', 'completada', NULL, 5, 'demo-20261029-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261029-004', '73541f90ef91f0b441922342c758780ae7bac20869c356b58c382cdf1394a2d3', 'creada', '2026-10-29 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (42, 13, 2, 32000, 64000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (13, 'egreso', 2, '2026-10-29 11:45:00', 'Venta #42', 42);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (42, 'efectivo', 32000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (42, 'tarjeta', 32000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (5, 'venta', 32000, '2026-10-29 11:45:00', 'Venta #42');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (43, '2026-10-29 12:30:00', 81000, 'efectivo', 'completada', NULL, 5, 'demo-20261029-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261029-005', '7dc7f6dd77bca021586a82724efcd0c01969d2f33a291fbc5bc65592054b995b', 'creada', '2026-10-29 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (43, 12, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (12, 'egreso', 2, '2026-10-29 12:30:00', 'Venta #43', 43);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (43, 6, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (6, 'egreso', 2, '2026-10-29 12:30:00', 'Venta #43', 43);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (43, 'efectivo', 81000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (5, 'venta', 81000, '2026-10-29 12:30:00', 'Venta #43');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (44, '2026-10-29 13:15:00', 123000, 'transferencia', 'completada', NULL, 5, 'demo-20261029-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261029-006', '873054e2908717a4213b7c90bfc2dec9e0af14f07734f752b902d16e731f4a47', 'creada', '2026-10-29 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (44, 15, 2, 32000, 64000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (15, 'egreso', 2, '2026-10-29 13:15:00', 'Venta #44', 44);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (44, 9, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 2, '2026-10-29 13:15:00', 'Venta #44', 44);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (44, 3, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (3, 'egreso', 1, '2026-10-29 13:15:00', 'Venta #44', 44);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (44, 'transferencia', 123000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (5, 'venta', 0, '2026-10-29 13:15:00', 'Venta #44');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (45, '2026-10-29 14:00:00', 15000, 'tarjeta', 'completada', NULL, 5, 'demo-20261029-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261029-007', '315896628f3c075ef5c37a4abeae969fc6a5dee862f516b11e9767bf48a9e1bd', 'creada', '2026-10-29 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (45, 4, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (4, 'egreso', 1, '2026-10-29 14:00:00', 'Venta #45', 45);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (45, 'tarjeta', 15000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (5, 'venta', 0, '2026-10-29 14:00:00', 'Venta #45');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (46, '2026-10-29 14:45:00', 58000, 'mixto', 'completada', NULL, 5, 'demo-20261029-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261029-008', '106c4800b63355fda31bd81ff2537a68450c7126d1b2648c6c99d83deaebcfa6', 'creada', '2026-10-29 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (46, 10, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (10, 'egreso', 1, '2026-10-29 14:45:00', 'Venta #46', 46);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (46, 19, 1, 36000, 36000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (19, 'egreso', 1, '2026-10-29 14:45:00', 'Venta #46', 46);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (46, 'efectivo', 29000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (46, 'tarjeta', 29000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (5, 'venta', 29000, '2026-10-29 14:45:00', 'Venta #46');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (5, 'retiro', 176000, '2026-10-29 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-10-29 20:00:00', efectivo_esperado=30000, efectivo_contado=29500, diferencia=-500 WHERE id=5;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (6, '2026-10-30 09:00:00', 20000, 'abierta');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (1, 'ingreso', 6, '2026-10-30 09:00:00', 'Reposicion de proveedor demo');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (2, 'ingreso', 6, '2026-10-30 09:00:00', 'Reposicion de proveedor demo');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (5, 'ingreso', 6, '2026-10-30 09:00:00', 'Reposicion de proveedor demo');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (9, 'ingreso', 6, '2026-10-30 09:00:00', 'Reposicion de proveedor demo');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (47, '2026-10-30 09:30:00', 37000, 'efectivo', 'completada', NULL, 6, 'demo-20261030-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261030-001', '0f2ccc6a265756457eadac6cb3079b2fd86788300ccd5ad3e78e41efbe20673b', 'creada', '2026-10-30 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (47, 7, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (7, 'egreso', 2, '2026-10-30 09:30:00', 'Venta #47', 47);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (47, 'efectivo', 37000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (6, 'venta', 37000, '2026-10-30 09:30:00', 'Venta #47');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (48, '2026-10-30 10:15:00', 82500, 'transferencia', 'completada', NULL, 6, 'demo-20261030-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261030-002', '00ad62663f585698ccee677b3560f4b812f8197100e27b8a5564e2ac70049928', 'creada', '2026-10-30 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (48, 13, 2, 32000, 64000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (13, 'egreso', 2, '2026-10-30 10:15:00', 'Venta #48', 48);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (48, 6, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (6, 'egreso', 1, '2026-10-30 10:15:00', 'Venta #48', 48);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (48, 'transferencia', 82500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (6, 'venta', 0, '2026-10-30 10:15:00', 'Venta #48');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (49, '2026-10-30 11:00:00', 77500, 'tarjeta', 'completada', NULL, 6, 'demo-20261030-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261030-003', '2def291f33c7923a961430a1d716cbdee865cdfb4180412298c8d4f941347644', 'creada', '2026-10-30 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (49, 12, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (12, 'egreso', 2, '2026-10-30 11:00:00', 'Venta #49', 49);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (49, 5, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 1, '2026-10-30 11:00:00', 'Venta #49', 49);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (49, 4, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (4, 'egreso', 1, '2026-10-30 11:00:00', 'Venta #49', 49);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (49, 'tarjeta', 77500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (6, 'venta', 0, '2026-10-30 11:00:00', 'Venta #49');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (50, '2026-10-30 11:45:00', 62000, 'mixto', 'completada', NULL, 6, 'demo-20261030-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261030-004', 'a4066471bef6854a27015abac7e100e62e3fad406714eabf948fbf481cfa870c', 'creada', '2026-10-30 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (50, 45, 2, 31000, 62000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (45, 'egreso', 2, '2026-10-30 11:45:00', 'Venta #50', 50);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (50, 'efectivo', 31000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (50, 'tarjeta', 31000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (6, 'venta', 31000, '2026-10-30 11:45:00', 'Venta #50');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (51, '2026-10-30 12:30:00', 66000, 'efectivo', 'completada', NULL, 6, 'demo-20261030-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261030-005', '305845b66696dad329d9cbfd8a6b619a6e226b6cce51959b2014835834a199cf', 'creada', '2026-10-30 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (51, 11, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (11, 'egreso', 2, '2026-10-30 12:30:00', 'Venta #51', 51);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (51, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-10-30 12:30:00', 'Venta #51', 51);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (51, 'efectivo', 66000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (6, 'venta', 66000, '2026-10-30 12:30:00', 'Venta #51');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (52, '2026-10-30 13:15:00', 116500, 'transferencia', 'completada', NULL, 6, 'demo-20261030-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261030-006', 'd7e40bc2a506c54b128940ca40d39fd17de3e3e06f7fb5de3110eafe95de2b25', 'creada', '2026-10-30 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (52, 22, 1, 42000, 42000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (22, 'egreso', 1, '2026-10-30 13:15:00', 'Venta #52', 52);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (52, 29, 1, 38500, 38500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (29, 'egreso', 1, '2026-10-30 13:15:00', 'Venta #52', 52);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (52, 17, 1, 36000, 36000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (17, 'egreso', 1, '2026-10-30 13:15:00', 'Venta #52', 52);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (52, 'transferencia', 116500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (6, 'venta', 0, '2026-10-30 13:15:00', 'Venta #52');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (53, '2026-10-30 14:00:00', 37000, 'tarjeta', 'completada', NULL, 6, 'demo-20261030-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261030-007', '6ce7b756ee9a8d3a0ebe7264984582c861ccfefcc7b344fb5a9de7c191c364f3', 'creada', '2026-10-30 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (53, 7, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (7, 'egreso', 2, '2026-10-30 14:00:00', 'Venta #53', 53);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (53, 'tarjeta', 37000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (6, 'venta', 0, '2026-10-30 14:00:00', 'Venta #53');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (54, '2026-10-30 14:45:00', 174000, 'mixto', 'completada', NULL, 6, 'demo-20261030-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261030-008', '7a483872dd9b603083d1d38138f2ec2598cf248e75ce37a560e4d194f0fca484', 'creada', '2026-10-30 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (54, 12, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (12, 'egreso', 2, '2026-10-30 14:45:00', 'Venta #54', 54);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (54, 34, 2, 65000, 130000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (34, 'egreso', 2, '2026-10-30 14:45:00', 'Venta #54', 54);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (54, 'efectivo', 87000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (54, 'tarjeta', 87000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (6, 'venta', 87000, '2026-10-30 14:45:00', 'Venta #54');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (55, '2026-10-30 15:30:00', 81000, 'efectivo', 'completada', NULL, 6, 'demo-20261030-009');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261030-009', '3d41a1a8117e54ec01edbf32468fe14f8e42d6bd9c1b45ad6cb44caaefb8e39b', 'creada', '2026-10-30 15:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (55, 10, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (10, 'egreso', 2, '2026-10-30 15:30:00', 'Venta #55', 55);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (55, 6, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (6, 'egreso', 1, '2026-10-30 15:30:00', 'Venta #55', 55);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (55, 8, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'egreso', 1, '2026-10-30 15:30:00', 'Venta #55', 55);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (55, 'efectivo', 81000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (6, 'venta', 81000, '2026-10-30 15:30:00', 'Venta #55');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (6, 'retiro', 292000, '2026-10-30 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-10-30 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=6;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (7, '2026-10-31 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (56, '2026-10-31 09:30:00', 30000, 'efectivo', 'completada', NULL, 7, 'demo-20261031-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261031-001', '3f455693beb76f9085cb622a6f54abac715ebf2530ea21eb59cf264550c5c190', 'creada', '2026-10-31 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (56, 4, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (4, 'egreso', 2, '2026-10-31 09:30:00', 'Venta #56', 56);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (56, 'efectivo', 30000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'venta', 30000, '2026-10-31 09:30:00', 'Venta #56');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (57, '2026-10-31 10:15:00', 94500, 'transferencia', 'completada', NULL, 7, 'demo-20261031-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261031-002', 'd3abe9ee9d85df95d692d9c3c66b2c828f92fc492279a3764fbf1a64646d8e41', 'creada', '2026-10-31 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (57, 25, 2, 28000, 56000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (25, 'egreso', 2, '2026-10-31 10:15:00', 'Venta #57', 57);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (57, 32, 1, 38500, 38500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (32, 'egreso', 1, '2026-10-31 10:15:00', 'Venta #57', 57);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (57, 'transferencia', 94500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'venta', 0, '2026-10-31 10:15:00', 'Venta #57');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (58, '2026-10-31 11:00:00', 67000, 'tarjeta', 'anulada', 'Cliente cancelo la compra', 7, 'demo-20261031-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261031-003', '8a5f8ef07680c444d9545429140d0e516e9c8470ae022d8d53f754ebc2213692', 'creada', '2026-10-31 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (58, 2, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 1, '2026-10-31 11:00:00', 'Venta #58', 58);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'devolucion', 1, '2026-10-31 11:15:00', 'Cliente cancelo la compra', 58);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (58, 3, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (3, 'egreso', 1, '2026-10-31 11:00:00', 'Venta #58', 58);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (3, 'devolucion', 1, '2026-10-31 11:15:00', 'Cliente cancelo la compra', 58);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (58, 8, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'egreso', 2, '2026-10-31 11:00:00', 'Venta #58', 58);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'devolucion', 2, '2026-10-31 11:15:00', 'Cliente cancelo la compra', 58);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (58, 'tarjeta', 67000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'venta', 0, '2026-10-31 11:00:00', 'Venta #58');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (59, '2026-10-31 11:45:00', 84000, 'mixto', 'completada', NULL, 7, 'demo-20261031-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261031-004', '8ab95e3b0308f5c604ffef3918942e1ce90b7ae37b5a3a7e3755d7b395edeb92', 'creada', '2026-10-31 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (59, 23, 2, 42000, 84000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (23, 'egreso', 2, '2026-10-31 11:45:00', 'Venta #59', 59);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (59, 'efectivo', 42000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (59, 'tarjeta', 42000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'venta', 42000, '2026-10-31 11:45:00', 'Venta #59');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (60, '2026-10-31 12:30:00', 55500, 'efectivo', 'completada', NULL, 7, 'demo-20261031-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261031-005', '41ff4a0efd79866ba7e0cf8f5b808bb26b240894b5d81838fc573c8d8e09cb68', 'creada', '2026-10-31 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (60, 8, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'egreso', 1, '2026-10-31 12:30:00', 'Venta #60', 60);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (60, 7, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (7, 'egreso', 2, '2026-10-31 12:30:00', 'Venta #60', 60);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (60, 'efectivo', 55500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'venta', 55500, '2026-10-31 12:30:00', 'Venta #60');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (61, '2026-10-31 13:15:00', 159500, 'transferencia', 'completada', NULL, 7, 'demo-20261031-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261031-006', '4bdbfec20ba6a3e23f7ad5945efaf5900fb6b9843b5b6ffc76e21851088bbc7d', 'creada', '2026-10-31 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (61, 23, 2, 42000, 84000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (23, 'egreso', 2, '2026-10-31 13:15:00', 'Venta #61', 61);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (61, 31, 1, 38500, 38500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (31, 'egreso', 1, '2026-10-31 13:15:00', 'Venta #61', 61);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (61, 8, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'egreso', 2, '2026-10-31 13:15:00', 'Venta #61', 61);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (61, 'transferencia', 159500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'venta', 0, '2026-10-31 13:15:00', 'Venta #61');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (62, '2026-10-31 14:00:00', 18500, 'tarjeta', 'completada', NULL, 7, 'demo-20261031-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261031-007', 'be0051e8c2fcd4beffce5c8c28cfc492ece19c04a568c7de73366305fa900378', 'creada', '2026-10-31 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (62, 8, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'egreso', 1, '2026-10-31 14:00:00', 'Venta #62', 62);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (62, 'tarjeta', 18500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'venta', 0, '2026-10-31 14:00:00', 'Venta #62');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (63, '2026-10-31 14:45:00', 93000, 'mixto', 'completada', NULL, 7, 'demo-20261031-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261031-008', '7f94cadd14bdd1947bcc1c631e6bd6ac3dbd8d280fd7b9a8b1cb09b2d77e4d6d', 'creada', '2026-10-31 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (63, 37, 1, 34000, 34000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (37, 'egreso', 1, '2026-10-31 14:45:00', 'Venta #63', 63);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (63, 44, 2, 29500, 59000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (44, 'egreso', 2, '2026-10-31 14:45:00', 'Venta #63', 63);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (63, 'efectivo', 46500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (63, 'tarjeta', 46500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'venta', 46500, '2026-10-31 14:45:00', 'Venta #63');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (64, '2026-10-31 15:30:00', 63500, 'efectivo', 'completada', NULL, 7, 'demo-20261031-009');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261031-009', '622afb845c6f4a9a56de13ebd3f53218745e88dd690d91d663a798a569c3254b', 'creada', '2026-10-31 15:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (64, 1, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 2, '2026-10-31 15:30:00', 'Venta #64', 64);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (64, 8, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'egreso', 1, '2026-10-31 15:30:00', 'Venta #64', 64);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (64, 4, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (4, 'egreso', 1, '2026-10-31 15:30:00', 'Venta #64', 64);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (64, 'efectivo', 63500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'venta', 63500, '2026-10-31 15:30:00', 'Venta #64');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (65, '2026-10-31 16:15:00', 62000, 'transferencia', 'completada', NULL, 7, 'demo-20261031-010');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261031-010', 'ea72886f0c0f5c423fff5768161b461328358316a57390ae8907632afe843aa4', 'creada', '2026-10-31 16:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (65, 45, 2, 31000, 62000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (45, 'egreso', 2, '2026-10-31 16:15:00', 'Venta #65', 65);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (65, 'transferencia', 62000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'venta', 0, '2026-10-31 16:15:00', 'Venta #65');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (7, 'retiro', 227500, '2026-10-31 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-10-31 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=7;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (8, '2026-11-01 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (66, '2026-11-01 09:30:00', 37000, 'efectivo', 'completada', NULL, 8, 'demo-20261101-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-001', '100ea1dc833e6a4258d6d7371aee7780369f469af3a853a0ebb6d6046edaab3d', 'creada', '2026-11-01 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (66, 5, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 2, '2026-11-01 09:30:00', 'Venta #66', 66);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (66, 'efectivo', 37000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 37000, '2026-11-01 09:30:00', 'Venta #66');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (67, '2026-11-01 10:15:00', 120000, 'transferencia', 'completada', NULL, 8, 'demo-20261101-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-002', '416006b0651f03af6dc05392422834fa649283cf343ff4362605fff4d7823b9e', 'creada', '2026-11-01 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (67, 26, 2, 28000, 56000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (26, 'egreso', 2, '2026-11-01 10:15:00', 'Venta #67', 67);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (67, 14, 2, 32000, 64000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (14, 'egreso', 2, '2026-11-01 10:15:00', 'Venta #67', 67);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (67, 'transferencia', 120000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 0, '2026-11-01 10:15:00', 'Venta #67');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (68, '2026-11-01 11:00:00', 111000, 'tarjeta', 'completada', NULL, 8, 'demo-20261101-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-003', '7e657aaaa813a370eef2fc9b8786dd4f87ac181bbb28df1fef7b5687972371a6', 'creada', '2026-11-01 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (68, 5, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 2, '2026-11-01 11:00:00', 'Venta #68', 68);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (68, 9, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 2, '2026-11-01 11:00:00', 'Venta #68', 68);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (68, 4, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (4, 'egreso', 2, '2026-11-01 11:00:00', 'Venta #68', 68);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (68, 'tarjeta', 111000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 0, '2026-11-01 11:00:00', 'Venta #68');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (69, '2026-11-01 11:45:00', 15000, 'mixto', 'completada', NULL, 8, 'demo-20261101-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-004', '545a80271d53d2cec08a8fb6f83ae277ebe96afacfc89841acdf0b2318b0945e', 'creada', '2026-11-01 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (69, 4, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (4, 'egreso', 1, '2026-11-01 11:45:00', 'Venta #69', 69);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (69, 'efectivo', 7500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (69, 'tarjeta', 7500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 7500, '2026-11-01 11:45:00', 'Venta #69');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (70, '2026-11-01 12:30:00', 55500, 'efectivo', 'completada', NULL, 8, 'demo-20261101-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-005', '58b5c08c72e043419f81edf2445705ad2b3f38e4f8a09e6db242469eec77f221', 'creada', '2026-11-01 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (70, 5, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 2, '2026-11-01 12:30:00', 'Venta #70', 70);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (70, 8, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'egreso', 1, '2026-11-01 12:30:00', 'Venta #70', 70);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (70, 'efectivo', 55500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 55500, '2026-11-01 12:30:00', 'Venta #70');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (71, '2026-11-01 13:15:00', 140000, 'transferencia', 'completada', NULL, 8, 'demo-20261101-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-006', '0e69d11fe74d09e598aff40450a6e3a6e2dc632383d12ead2302bf5e4fa06163', 'creada', '2026-11-01 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (71, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-11-01 13:15:00', 'Venta #71', 71);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (71, 40, 1, 34000, 34000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (40, 'egreso', 1, '2026-11-01 13:15:00', 'Venta #71', 71);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (71, 23, 2, 42000, 84000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (23, 'egreso', 2, '2026-11-01 13:15:00', 'Venta #71', 71);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (71, 'transferencia', 140000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 0, '2026-11-01 13:15:00', 'Venta #71');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (72, '2026-11-01 14:00:00', 30000, 'tarjeta', 'completada', NULL, 8, 'demo-20261101-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-007', '31fdda35ef127db06dbfcc5ac76610e6d6c603f3c7ae2e1e7d10ff4ceb513dcf', 'creada', '2026-11-01 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (72, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-11-01 14:00:00', 'Venta #72', 72);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (72, 'tarjeta', 30000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 0, '2026-11-01 14:00:00', 'Venta #72');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (73, '2026-11-01 14:45:00', 115000, 'mixto', 'completada', NULL, 8, 'demo-20261101-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-008', '2a7a3faf16fec2f32621730250cf9969b17efc9863d18ab7bd4f899a2b184d14', 'creada', '2026-11-01 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (73, 21, 2, 42000, 84000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (21, 'egreso', 2, '2026-11-01 14:45:00', 'Venta #73', 73);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (73, 46, 1, 31000, 31000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (46, 'egreso', 1, '2026-11-01 14:45:00', 'Venta #73', 73);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (73, 'efectivo', 57500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (73, 'tarjeta', 57500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 57500, '2026-11-01 14:45:00', 'Venta #73');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (74, '2026-11-01 15:30:00', 63500, 'efectivo', 'completada', NULL, 8, 'demo-20261101-009');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-009', '30c2ad92ffa859f8f5fe061ea70160e6a5793efb21a3a31a7bce2ade9abf713a', 'creada', '2026-11-01 15:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (74, 5, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 1, '2026-11-01 15:30:00', 'Venta #74', 74);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (74, 3, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (3, 'egreso', 2, '2026-11-01 15:30:00', 'Venta #74', 74);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (74, 2, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 1, '2026-11-01 15:30:00', 'Venta #74', 74);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (74, 'efectivo', 63500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 63500, '2026-11-01 15:30:00', 'Venta #74');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (75, '2026-11-01 16:15:00', 29500, 'transferencia', 'completada', NULL, 8, 'demo-20261101-010');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-010', '53f9f04b483dbdaa7bed349ebfac55cb9fe7fa632e3bc7bd1fa4af68c7d34cb9', 'creada', '2026-11-01 16:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (75, 44, 1, 29500, 29500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (44, 'egreso', 1, '2026-11-01 16:15:00', 'Venta #75', 75);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (75, 'transferencia', 29500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 0, '2026-11-01 16:15:00', 'Venta #75');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (76, '2026-11-01 17:00:00', 40500, 'tarjeta', 'completada', NULL, 8, 'demo-20261101-011');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261101-011', 'fe08adc298eb3bb2dcf11d912f5ef397f5658cde689687e9d1809354dfe6f910', 'creada', '2026-11-01 17:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (76, 5, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 1, '2026-11-01 17:00:00', 'Venta #76', 76);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (76, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-11-01 17:00:00', 'Venta #76', 76);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (76, 'tarjeta', 40500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'venta', 0, '2026-11-01 17:00:00', 'Venta #76');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (8, 'retiro', 211000, '2026-11-01 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-11-01 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=8;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (9, '2026-11-02 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (77, '2026-11-02 09:30:00', 37000, 'efectivo', 'completada', NULL, 9, 'demo-20261102-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261102-001', 'c0b22b01ae1ccbe03179f77456915265e73bacb89288158e3182e26e63ea5481', 'creada', '2026-11-02 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (77, 8, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (8, 'egreso', 2, '2026-11-02 09:30:00', 'Venta #77', 77);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (77, 'efectivo', 37000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (9, 'venta', 37000, '2026-11-02 09:30:00', 'Venta #77');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (78, '2026-11-02 10:15:00', 110500, 'transferencia', 'completada', NULL, 9, 'demo-20261102-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261102-002', '937e559b021f3af9fc1e1d16e5de80e7af6bca64fd82772b7a86a5c70b6ea7ee', 'creada', '2026-11-02 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (78, 32, 1, 38500, 38500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (32, 'egreso', 1, '2026-11-02 10:15:00', 'Venta #78', 78);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (78, 19, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (19, 'egreso', 2, '2026-11-02 10:15:00', 'Venta #78', 78);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (78, 'transferencia', 110500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (9, 'venta', 0, '2026-11-02 10:15:00', 'Venta #78');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (79, '2026-11-02 11:00:00', 78500, 'tarjeta', 'completada', NULL, 9, 'demo-20261102-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261102-003', '9ad61d9707748295a987820d18ff2d65a8a49ed2ad31e5a4fb248009c852f9e4', 'creada', '2026-11-02 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (79, 5, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 1, '2026-11-02 11:00:00', 'Venta #79', 79);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (79, 1, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 2, '2026-11-02 11:00:00', 'Venta #79', 79);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (79, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-11-02 11:00:00', 'Venta #79', 79);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (79, 'tarjeta', 78500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (9, 'venta', 0, '2026-11-02 11:00:00', 'Venta #79');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (80, '2026-11-02 11:45:00', 44000, 'mixto', 'completada', NULL, 9, 'demo-20261102-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261102-004', '403070fb10e5fe1536e656b2c3b928e974b753cb34bf709ecc2f52a482b15838', 'creada', '2026-11-02 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (80, 10, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (10, 'egreso', 2, '2026-11-02 11:45:00', 'Venta #80', 80);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (80, 'efectivo', 22000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (80, 'tarjeta', 22000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (9, 'venta', 22000, '2026-11-02 11:45:00', 'Venta #80');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (81, '2026-11-02 12:30:00', 88000, 'efectivo', 'completada', NULL, 9, 'demo-20261102-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261102-005', 'e3cfefb9d5d37da556cce0cdc13e7e8f05c4088785bfc06b12782ee4c0863b1f', 'creada', '2026-11-02 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (81, 9, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 2, '2026-11-02 12:30:00', 'Venta #81', 81);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (81, 10, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (10, 'egreso', 2, '2026-11-02 12:30:00', 'Venta #81', 81);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (81, 'efectivo', 88000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (9, 'venta', 88000, '2026-11-02 12:30:00', 'Venta #81');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (82, '2026-11-02 13:15:00', 115000, 'transferencia', 'completada', NULL, 9, 'demo-20261102-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261102-006', 'b1740981016ac680d1a303b96e9405ada6e8a8c818df19f2c26f454d1e1b71a0', 'creada', '2026-11-02 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (82, 16, 2, 32000, 64000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (16, 'egreso', 2, '2026-11-02 13:15:00', 'Venta #82', 82);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (82, 1, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 1, '2026-11-02 13:15:00', 'Venta #82', 82);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (82, 17, 1, 36000, 36000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (17, 'egreso', 1, '2026-11-02 13:15:00', 'Venta #82', 82);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (82, 'transferencia', 115000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (9, 'venta', 0, '2026-11-02 13:15:00', 'Venta #82');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (83, '2026-11-02 14:00:00', 30000, 'tarjeta', 'completada', NULL, 9, 'demo-20261102-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261102-007', 'c1db775b76425c6aa765257960adac133eb1e337a361db24264234f6701b4cd0', 'creada', '2026-11-02 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (83, 1, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 2, '2026-11-02 14:00:00', 'Venta #83', 83);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (83, 'tarjeta', 30000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (9, 'venta', 0, '2026-11-02 14:00:00', 'Venta #83');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (84, '2026-11-02 14:45:00', 172000, 'mixto', 'completada', NULL, 9, 'demo-20261102-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261102-008', 'ab5a07a3437928afd0dc478ee2b211baeb4eea112b3d4453f7574add283ad628', 'creada', '2026-11-02 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (84, 21, 1, 42000, 42000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (21, 'egreso', 1, '2026-11-02 14:45:00', 'Venta #84', 84);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (84, 33, 2, 65000, 130000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (33, 'egreso', 2, '2026-11-02 14:45:00', 'Venta #84', 84);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (84, 'efectivo', 86000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (84, 'tarjeta', 86000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (9, 'venta', 86000, '2026-11-02 14:45:00', 'Venta #84');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (9, 'retiro', 223000, '2026-11-02 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-11-02 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=9;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (10, '2026-11-03 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (85, '2026-11-03 09:30:00', 44000, 'efectivo', 'completada', NULL, 10, 'demo-20261103-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261103-001', 'abaab5d7af30e4bd0cc06b7ce7a19c6cffcbc5fec8a0e06833aded771b04bd86', 'creada', '2026-11-03 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (85, 9, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 2, '2026-11-03 09:30:00', 'Venta #85', 85);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (85, 'efectivo', 44000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (10, 'venta', 44000, '2026-11-03 09:30:00', 'Venta #85');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (86, '2026-11-03 10:15:00', 101000, 'transferencia', 'completada', NULL, 10, 'demo-20261103-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261103-002', '048f8ea1c0a0d2d124a6ee0b2d0f0bf0cd3612cc90c62f61de8f664c95b7e94b', 'creada', '2026-11-03 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (86, 24, 1, 42000, 42000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (24, 'egreso', 1, '2026-11-03 10:15:00', 'Venta #86', 86);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (86, 42, 2, 29500, 59000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (42, 'egreso', 2, '2026-11-03 10:15:00', 'Venta #86', 86);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (86, 'transferencia', 101000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (10, 'venta', 0, '2026-11-03 10:15:00', 'Venta #86');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (87, '2026-11-03 11:00:00', 55500, 'tarjeta', 'completada', NULL, 10, 'demo-20261103-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261103-003', '455aeffb79f1aed5bd9b70065b9c9361e2a389361560fe202eb46f76211c1cd7', 'creada', '2026-11-03 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (87, 5, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 1, '2026-11-03 11:00:00', 'Venta #87', 87);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (87, 1, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 1, '2026-11-03 11:00:00', 'Venta #87', 87);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (87, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-11-03 11:00:00', 'Venta #87', 87);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (87, 'tarjeta', 55500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (10, 'venta', 0, '2026-11-03 11:00:00', 'Venta #87');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (88, '2026-11-03 11:45:00', 56000, 'mixto', 'completada', NULL, 10, 'demo-20261103-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261103-004', '8fe956a949f32cc79bc36580d995f50d702c051604c8fe5af6bbdf07e819b936', 'creada', '2026-11-03 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (88, 26, 2, 28000, 56000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (26, 'egreso', 2, '2026-11-03 11:45:00', 'Venta #88', 88);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (88, 'efectivo', 28000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (88, 'tarjeta', 28000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (10, 'venta', 28000, '2026-11-03 11:45:00', 'Venta #88');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (89, '2026-11-03 12:30:00', 48500, 'efectivo', 'completada', NULL, 10, 'demo-20261103-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261103-005', 'c2f9c3be203888d85038428726e8dabd80bf778ae8929dc9a4ed7e3e8a706bb1', 'creada', '2026-11-03 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (89, 5, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 1, '2026-11-03 12:30:00', 'Venta #89', 89);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (89, 1, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 2, '2026-11-03 12:30:00', 'Venta #89', 89);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (89, 'efectivo', 48500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (10, 'venta', 48500, '2026-11-03 12:30:00', 'Venta #89');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (90, '2026-11-03 13:15:00', 110500, 'transferencia', 'completada', NULL, 10, 'demo-20261103-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261103-006', '03bb2d719078a43a89fae82139843c3835f436040b8f97b6b0476d524199f1e5', 'creada', '2026-11-03 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (90, 26, 2, 28000, 56000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (26, 'egreso', 2, '2026-11-03 13:15:00', 'Venta #90', 90);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (90, 18, 1, 36000, 36000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (18, 'egreso', 1, '2026-11-03 13:15:00', 'Venta #90', 90);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (90, 5, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 1, '2026-11-03 13:15:00', 'Venta #90', 90);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (90, 'transferencia', 110500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (10, 'venta', 0, '2026-11-03 13:15:00', 'Venta #90');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (91, '2026-11-03 14:00:00', 15000, 'tarjeta', 'completada', NULL, 10, 'demo-20261103-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261103-007', 'a46c69d9670c407fbba04efd25f86f49b2ff73cd5448b04766cddc5969e33613', 'creada', '2026-11-03 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (91, 2, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 1, '2026-11-03 14:00:00', 'Venta #91', 91);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (91, 'tarjeta', 15000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (10, 'venta', 0, '2026-11-03 14:00:00', 'Venta #91');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (92, '2026-11-03 14:45:00', 71500, 'mixto', 'completada', NULL, 10, 'demo-20261103-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261103-008', 'f0a91794fb6e923989cd9a7467741149edea076925ee6256d29e27793f6594c0', 'creada', '2026-11-03 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (92, 44, 1, 29500, 29500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (44, 'egreso', 1, '2026-11-03 14:45:00', 'Venta #92', 92);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (92, 23, 1, 42000, 42000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (23, 'egreso', 1, '2026-11-03 14:45:00', 'Venta #92', 92);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (92, 'efectivo', 35750);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (92, 'tarjeta', 35750);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (10, 'venta', 35750, '2026-11-03 14:45:00', 'Venta #92');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (93, '2026-11-03 15:30:00', 15000, 'efectivo', 'completada', NULL, 10, 'demo-20261103-009');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261103-009', 'c03449f988cfd4dc3b0f695d1aceaabafdfd0b7b61c4f5fea9ae964ecfbfa82a', 'creada', '2026-11-03 15:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (93, 2, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 1, '2026-11-03 15:30:00', 'Venta #93', 93);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (93, 'efectivo', 15000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (10, 'venta', 15000, '2026-11-03 15:30:00', 'Venta #93');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (10, 'retiro', 161250, '2026-11-03 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-11-03 20:00:00', efectivo_esperado=30000, efectivo_contado=30200, diferencia=200 WHERE id=10;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (11, '2026-11-04 09:00:00', 20000, 'abierta');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (1, 'ingreso', 6, '2026-11-04 09:00:00', 'Reposicion de proveedor demo');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (2, 'ingreso', 6, '2026-11-04 09:00:00', 'Reposicion de proveedor demo');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (5, 'ingreso', 6, '2026-11-04 09:00:00', 'Reposicion de proveedor demo');
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo) VALUES (9, 'ingreso', 6, '2026-11-04 09:00:00', 'Reposicion de proveedor demo');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (94, '2026-11-04 09:30:00', 30000, 'efectivo', 'completada', NULL, 11, 'demo-20261104-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261104-001', '8a03a799c47c4a6280fb03e6f7321ce7824cf63ec997456fff38eba9023ecede', 'creada', '2026-11-04 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (94, 1, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 2, '2026-11-04 09:30:00', 'Venta #94', 94);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (94, 'efectivo', 30000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'venta', 30000, '2026-11-04 09:30:00', 'Venta #94');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (95, '2026-11-04 10:15:00', 94000, 'transferencia', 'completada', NULL, 11, 'demo-20261104-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261104-002', 'ef087ee96ecd5894dd2830946977b993bb011ebe9d937da1c8a11f356a8febc3', 'creada', '2026-11-04 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (95, 1, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 2, '2026-11-04 10:15:00', 'Venta #95', 95);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (95, 15, 2, 32000, 64000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (15, 'egreso', 2, '2026-11-04 10:15:00', 'Venta #95', 95);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (95, 'transferencia', 94000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'venta', 0, '2026-11-04 10:15:00', 'Venta #95');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (96, '2026-11-04 11:00:00', 89000, 'tarjeta', 'anulada', 'Cliente cancelo la compra', 11, 'demo-20261104-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261104-003', '4a3fb9a466b68836883fb87170fe1b84a7d7e4a4b47bc8fb1ad58ae40d363208', 'creada', '2026-11-04 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (96, 5, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 2, '2026-11-04 11:00:00', 'Venta #96', 96);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'devolucion', 2, '2026-11-04 11:15:00', 'Cliente cancelo la compra', 96);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (96, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-11-04 11:00:00', 'Venta #96', 96);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'devolucion', 2, '2026-11-04 11:15:00', 'Cliente cancelo la compra', 96);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (96, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-11-04 11:00:00', 'Venta #96', 96);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'devolucion', 1, '2026-11-04 11:15:00', 'Cliente cancelo la compra', 96);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (96, 'tarjeta', 89000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'venta', 0, '2026-11-04 11:00:00', 'Venta #96');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (97, '2026-11-04 11:45:00', 72000, 'mixto', 'completada', NULL, 11, 'demo-20261104-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261104-004', '13d13599ca3969769a55d604b1c9167b6860a41dbb23c535289fca2324fe21bc', 'creada', '2026-11-04 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (97, 20, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (20, 'egreso', 2, '2026-11-04 11:45:00', 'Venta #97', 97);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (97, 'efectivo', 36000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (97, 'tarjeta', 36000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'venta', 36000, '2026-11-04 11:45:00', 'Venta #97');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (98, '2026-11-04 12:30:00', 37000, 'efectivo', 'completada', NULL, 11, 'demo-20261104-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261104-005', '163548c7afd94d05a8bfe61c5fd4159cbb21c3e6a3ae894b6912f71d878c332c', 'creada', '2026-11-04 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (98, 2, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 1, '2026-11-04 12:30:00', 'Venta #98', 98);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (98, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-11-04 12:30:00', 'Venta #98', 98);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (98, 'efectivo', 37000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'venta', 37000, '2026-11-04 12:30:00', 'Venta #98');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (99, '2026-11-04 13:15:00', 116000, 'transferencia', 'completada', NULL, 11, 'demo-20261104-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261104-006', '218be35548ebe9c4e8a9a9c6fa48bcc0290f80205f0bcbdde1530dfa1f6747d0', 'creada', '2026-11-04 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (99, 5, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 2, '2026-11-04 13:15:00', 'Venta #99', 99);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (99, 1, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 1, '2026-11-04 13:15:00', 'Venta #99', 99);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (99, 13, 2, 32000, 64000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (13, 'egreso', 2, '2026-11-04 13:15:00', 'Venta #99', 99);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (99, 'transferencia', 116000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'venta', 0, '2026-11-04 13:15:00', 'Venta #99');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (100, '2026-11-04 14:00:00', 44000, 'tarjeta', 'completada', NULL, 11, 'demo-20261104-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261104-007', '8d1bc1a5329e575899fa3c6047cf887484b87631f879b74ea65c4768b3281f46', 'creada', '2026-11-04 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (100, 9, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 2, '2026-11-04 14:00:00', 'Venta #100', 100);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (100, 'tarjeta', 44000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'venta', 0, '2026-11-04 14:00:00', 'Venta #100');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (101, '2026-11-04 14:45:00', 97000, 'mixto', 'completada', NULL, 11, 'demo-20261104-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261104-008', '0f10ec4fc07f4050402807e07259e7f22a90c23aa8a4ef65f6f9017aa795bb6a', 'creada', '2026-11-04 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (101, 33, 1, 65000, 65000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (33, 'egreso', 1, '2026-11-04 14:45:00', 'Venta #101', 101);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (101, 15, 1, 32000, 32000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (15, 'egreso', 1, '2026-11-04 14:45:00', 'Venta #101', 101);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (101, 'efectivo', 48500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (101, 'tarjeta', 48500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'venta', 48500, '2026-11-04 14:45:00', 'Venta #101');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (102, '2026-11-04 15:30:00', 67000, 'efectivo', 'completada', NULL, 11, 'demo-20261104-009');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261104-009', '3fd307491257a45c37eff924015048b99ea3cb442d6424acfa9ea1c1f37b73af', 'creada', '2026-11-04 15:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (102, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-11-04 15:30:00', 'Venta #102', 102);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (102, 1, 1, 15000, 15000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (1, 'egreso', 1, '2026-11-04 15:30:00', 'Venta #102', 102);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (102, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-11-04 15:30:00', 'Venta #102', 102);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (102, 'efectivo', 67000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'venta', 67000, '2026-11-04 15:30:00', 'Venta #102');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (103, '2026-11-04 16:15:00', 65000, 'transferencia', 'completada', NULL, 11, 'demo-20261104-010');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261104-010', '5a147721b3ae8e2f80adb03c5c945178bc7b6d9169fbe6a04438d5140e3effc0', 'creada', '2026-11-04 16:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (103, 35, 1, 65000, 65000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (35, 'egreso', 1, '2026-11-04 16:15:00', 'Venta #103', 103);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (103, 'transferencia', 65000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'venta', 0, '2026-11-04 16:15:00', 'Venta #103');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (11, 'retiro', 208500, '2026-11-04 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-11-04 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=11;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (12, '2026-11-05 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (104, '2026-11-05 09:30:00', 22000, 'efectivo', 'completada', NULL, 12, 'demo-20261105-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-001', 'ee1bb3df98d93285d675d2caa4e47ea46efe62640d57c2b07be81b008d62936e', 'creada', '2026-11-05 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (104, 9, 1, 22000, 22000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 1, '2026-11-05 09:30:00', 'Venta #104', 104);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (104, 'efectivo', 22000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 22000, '2026-11-05 09:30:00', 'Venta #104');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (105, '2026-11-05 10:15:00', 133000, 'transferencia', 'completada', NULL, 12, 'demo-20261105-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-002', 'c15d2ea2731e1e65d4b3cab5d6d8fc64e1f2f1c291e78685c488ddeeab12ee62', 'creada', '2026-11-05 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (105, 38, 2, 34000, 68000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (38, 'egreso', 2, '2026-11-05 10:15:00', 'Venta #105', 105);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (105, 34, 1, 65000, 65000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (34, 'egreso', 1, '2026-11-05 10:15:00', 'Venta #105', 105);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (105, 'transferencia', 133000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 0, '2026-11-05 10:15:00', 'Venta #105');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (106, '2026-11-05 11:00:00', 111000, 'tarjeta', 'completada', NULL, 12, 'demo-20261105-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-003', '54535fa72df9d06c36b2c0712353691429e2fce3b144b02dadb9154abe8eac01', 'creada', '2026-11-05 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (106, 9, 2, 22000, 44000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (9, 'egreso', 2, '2026-11-05 11:00:00', 'Venta #106', 106);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (106, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-11-05 11:00:00', 'Venta #106', 106);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (106, 5, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 2, '2026-11-05 11:00:00', 'Venta #106', 106);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (106, 'tarjeta', 111000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 0, '2026-11-05 11:00:00', 'Venta #106');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (107, '2026-11-05 11:45:00', 59000, 'mixto', 'completada', NULL, 12, 'demo-20261105-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-004', 'e942b0294aa6ac2d5ef38d5d7a457d3d76d8c99334e1c299ad945bf0964c2509', 'creada', '2026-11-05 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (107, 43, 2, 29500, 59000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (43, 'egreso', 2, '2026-11-05 11:45:00', 'Venta #107', 107);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (107, 'efectivo', 29500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (107, 'tarjeta', 29500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 29500, '2026-11-05 11:45:00', 'Venta #107');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (108, '2026-11-05 12:30:00', 48500, 'efectivo', 'completada', NULL, 12, 'demo-20261105-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-005', 'ed0d4615f1f3001182716776d32c1d43633da61265fbdf5c2ed79c861acb14f8', 'creada', '2026-11-05 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (108, 5, 1, 18500, 18500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 1, '2026-11-05 12:30:00', 'Venta #108', 108);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (108, 2, 2, 15000, 30000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (2, 'egreso', 2, '2026-11-05 12:30:00', 'Venta #108', 108);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (108, 'efectivo', 48500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 48500, '2026-11-05 12:30:00', 'Venta #108');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (109, '2026-11-05 13:15:00', 185500, 'transferencia', 'completada', NULL, 12, 'demo-20261105-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-006', '60ecf0b12f34dc47b0c43453d10c5d8c67c3a638050e49644f7b48c85c6fd477', 'creada', '2026-11-05 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (109, 44, 1, 29500, 29500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (44, 'egreso', 1, '2026-11-05 13:15:00', 'Venta #109', 109);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (109, 23, 2, 42000, 84000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (23, 'egreso', 2, '2026-11-05 13:15:00', 'Venta #109', 109);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (109, 18, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (18, 'egreso', 2, '2026-11-05 13:15:00', 'Venta #109', 109);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (109, 'transferencia', 185500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 0, '2026-11-05 13:15:00', 'Venta #109');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (110, '2026-11-05 14:00:00', 37000, 'tarjeta', 'completada', NULL, 12, 'demo-20261105-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-007', 'b721160c88455724defa170206f82c50480a51a814e07a15d0eff379ca07af5e', 'creada', '2026-11-05 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (110, 5, 2, 18500, 37000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (5, 'egreso', 2, '2026-11-05 14:00:00', 'Venta #110', 110);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (110, 'tarjeta', 37000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 0, '2026-11-05 14:00:00', 'Venta #110');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (111, '2026-11-05 14:45:00', 124000, 'mixto', 'completada', NULL, 12, 'demo-20261105-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-008', '5ffb8d7f6c04d884e139a9b3f5ef4528f9511e39bd2ffded5e12ba02050345b6', 'creada', '2026-11-05 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (111, 44, 2, 29500, 59000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (44, 'egreso', 2, '2026-11-05 14:45:00', 'Venta #111', 111);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (111, 35, 1, 65000, 65000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (35, 'egreso', 1, '2026-11-05 14:45:00', 'Venta #111', 111);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (111, 'efectivo', 62000);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (111, 'tarjeta', 62000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 62000, '2026-11-05 14:45:00', 'Venta #111');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (112, '2026-11-05 15:30:00', 171000, 'efectivo', 'completada', NULL, 12, 'demo-20261105-009');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-009', 'bf3f288c326ef309badf830d2c15303bd2b7d37e5b43755552225527fe2cef54', 'creada', '2026-11-05 15:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (112, 21, 1, 42000, 42000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (21, 'egreso', 1, '2026-11-05 15:30:00', 'Venta #112', 112);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (112, 14, 2, 32000, 64000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (14, 'egreso', 2, '2026-11-05 15:30:00', 'Venta #112', 112);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (112, 34, 1, 65000, 65000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (34, 'egreso', 1, '2026-11-05 15:30:00', 'Venta #112', 112);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (112, 'efectivo', 171000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 171000, '2026-11-05 15:30:00', 'Venta #112');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (113, '2026-11-05 16:15:00', 31000, 'transferencia', 'completada', NULL, 12, 'demo-20261105-010');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-010', '8e09d838b7c96c2a2514bdeaeae9238ef8fa00b2a904ab750289097e3a999416', 'creada', '2026-11-05 16:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (113, 47, 1, 31000, 31000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (47, 'egreso', 1, '2026-11-05 16:15:00', 'Venta #113', 113);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (113, 'transferencia', 31000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 0, '2026-11-05 16:15:00', 'Venta #113');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (114, '2026-11-05 17:00:00', 74000, 'tarjeta', 'completada', NULL, 12, 'demo-20261105-011');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261105-011', '713cfe0fed6edd27ece5045249ceb4403a80921b980e6e57743b27dfdb165033', 'creada', '2026-11-05 17:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (114, 21, 1, 42000, 42000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (21, 'egreso', 1, '2026-11-05 17:00:00', 'Venta #114', 114);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (114, 16, 1, 32000, 32000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (16, 'egreso', 1, '2026-11-05 17:00:00', 'Venta #114', 114);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (114, 'tarjeta', 74000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'venta', 0, '2026-11-05 17:00:00', 'Venta #114');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (12, 'retiro', 323000, '2026-11-05 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-11-05 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=12;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (13, '2026-11-06 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (115, '2026-11-06 09:30:00', 34000, 'efectivo', 'completada', NULL, 13, 'demo-20261106-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261106-001', '2252f7ddb1dc4af5f09396188e9f3049db829affac20d87edb2dc377e276e973', 'creada', '2026-11-06 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (115, 37, 1, 34000, 34000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (37, 'egreso', 1, '2026-11-06 09:30:00', 'Venta #115', 115);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (115, 'efectivo', 34000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (13, 'venta', 34000, '2026-11-06 09:30:00', 'Venta #115');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (116, '2026-11-06 10:15:00', 80500, 'transferencia', 'completada', NULL, 13, 'demo-20261106-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261106-002', '7b57311fee3ea0f742a8025953cd484959bc298a2c91f0f635eff32e6c3d23db', 'creada', '2026-11-06 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (116, 22, 1, 42000, 42000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (22, 'egreso', 1, '2026-11-06 10:15:00', 'Venta #116', 116);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (116, 30, 1, 38500, 38500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (30, 'egreso', 1, '2026-11-06 10:15:00', 'Venta #116', 116);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (116, 'transferencia', 80500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (13, 'venta', 0, '2026-11-06 10:15:00', 'Venta #116');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (117, '2026-11-06 11:00:00', 145500, 'tarjeta', 'completada', NULL, 13, 'demo-20261106-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261106-003', '9eb563ca29192ec19d923a1fe144df07935e25cddbdeb57e01b6838febc009d1', 'creada', '2026-11-06 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (117, 35, 1, 65000, 65000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (35, 'egreso', 1, '2026-11-06 11:00:00', 'Venta #117', 117);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (117, 29, 1, 38500, 38500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (29, 'egreso', 1, '2026-11-06 11:00:00', 'Venta #117', 117);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (117, 23, 1, 42000, 42000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (23, 'egreso', 1, '2026-11-06 11:00:00', 'Venta #117', 117);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (117, 'tarjeta', 145500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (13, 'venta', 0, '2026-11-06 11:00:00', 'Venta #117');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (118, '2026-11-06 11:45:00', 31000, 'mixto', 'completada', NULL, 13, 'demo-20261106-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261106-004', '7d4d0daa8da706588bdab76f96ca65fc99a302d3c1e368866066cfadd5f8f3b7', 'creada', '2026-11-06 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (118, 46, 1, 31000, 31000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (46, 'egreso', 1, '2026-11-06 11:45:00', 'Venta #118', 118);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (118, 'efectivo', 15500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (118, 'tarjeta', 15500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (13, 'venta', 15500, '2026-11-06 11:45:00', 'Venta #118');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (119, '2026-11-06 12:30:00', 100000, 'efectivo', 'completada', NULL, 13, 'demo-20261106-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261106-005', '16cd41c932ba8d75b99efc547fa74c56e177e2e3401e81b86e3ff3da3e6b4fee', 'creada', '2026-11-06 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (119, 26, 1, 28000, 28000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (26, 'egreso', 1, '2026-11-06 12:30:00', 'Venta #119', 119);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (119, 19, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (19, 'egreso', 2, '2026-11-06 12:30:00', 'Venta #119', 119);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (119, 'efectivo', 100000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (13, 'venta', 100000, '2026-11-06 12:30:00', 'Venta #119');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (120, '2026-11-06 13:15:00', 251000, 'transferencia', 'completada', NULL, 13, 'demo-20261106-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261106-006', 'd2f4a26fd8a6c7ee44e56dad5a4fad2ec40c2e1d17d07d3301661fa19ccdb4e1', 'creada', '2026-11-06 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (120, 27, 2, 28000, 56000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (27, 'egreso', 2, '2026-11-06 13:15:00', 'Venta #120', 120);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (120, 33, 1, 65000, 65000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (33, 'egreso', 1, '2026-11-06 13:15:00', 'Venta #120', 120);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (120, 35, 2, 65000, 130000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (35, 'egreso', 2, '2026-11-06 13:15:00', 'Venta #120', 120);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (120, 'transferencia', 251000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (13, 'venta', 0, '2026-11-06 13:15:00', 'Venta #120');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (121, '2026-11-06 14:00:00', 56000, 'tarjeta', 'completada', NULL, 13, 'demo-20261106-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261106-007', 'a13e3b51e8ab7cba77bed1fac4ec230c876a48ee94ea6b3dd8be21211f6eaed5', 'creada', '2026-11-06 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (121, 25, 2, 28000, 56000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (25, 'egreso', 2, '2026-11-06 14:00:00', 'Venta #121', 121);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (121, 'tarjeta', 56000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (13, 'venta', 0, '2026-11-06 14:00:00', 'Venta #121');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (122, '2026-11-06 14:45:00', 65500, 'mixto', 'completada', NULL, 13, 'demo-20261106-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261106-008', 'de55e040580d72a47427171309a4f6e7a6f80e2d94b6c2fbced0245ee4b3993f', 'creada', '2026-11-06 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (122, 43, 1, 29500, 29500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (43, 'egreso', 1, '2026-11-06 14:45:00', 'Venta #122', 122);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (122, 17, 1, 36000, 36000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (17, 'egreso', 1, '2026-11-06 14:45:00', 'Venta #122', 122);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (122, 'efectivo', 32750);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (122, 'tarjeta', 32750);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (13, 'venta', 32750, '2026-11-06 14:45:00', 'Venta #122');
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (13, 'retiro', 172250, '2026-11-06 19:00:00', 'Retiro al cierre demo');
UPDATE caja SET estado='cerrada', fecha_cierre='2026-11-06 20:00:00', efectivo_esperado=30000, efectivo_contado=30000, diferencia=0 WHERE id=13;
INSERT INTO caja (id, fecha_apertura, saldo_inicial, estado) VALUES (14, '2026-11-07 09:00:00', 20000, 'abierta');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (123, '2026-11-07 09:30:00', 72000, 'efectivo', 'completada', NULL, 14, 'demo-20261107-001');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261107-001', 'd08de9d90760177560057bea76da6eb0ed5d43a4da2c0c6776bc68ac4cfb9df7', 'creada', '2026-11-07 09:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (123, 18, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (18, 'egreso', 2, '2026-11-07 09:30:00', 'Venta #123', 123);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (123, 'efectivo', 72000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (14, 'venta', 72000, '2026-11-07 09:30:00', 'Venta #123');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (124, '2026-11-07 10:15:00', 101500, 'transferencia', 'completada', NULL, 14, 'demo-20261107-002');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261107-002', '615593e2851b5459ac1f8defcafcff5621eba91927163f9ad23c8eb8dc6b9219', 'creada', '2026-11-07 10:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (124, 42, 1, 29500, 29500);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (42, 'egreso', 1, '2026-11-07 10:15:00', 'Venta #124', 124);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (124, 18, 2, 36000, 72000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (18, 'egreso', 2, '2026-11-07 10:15:00', 'Venta #124', 124);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (124, 'transferencia', 101500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (14, 'venta', 0, '2026-11-07 10:15:00', 'Venta #124');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (125, '2026-11-07 11:00:00', 217000, 'tarjeta', 'completada', NULL, 14, 'demo-20261107-003');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261107-003', '7ae82e69a5671a49239ea2393530949c442094eda11aa345a94d1b1911ddf352', 'creada', '2026-11-07 11:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (125, 29, 2, 38500, 77000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (29, 'egreso', 2, '2026-11-07 11:00:00', 'Venta #125', 125);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (125, 22, 2, 42000, 84000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (22, 'egreso', 2, '2026-11-07 11:00:00', 'Venta #125', 125);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (125, 28, 2, 28000, 56000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (28, 'egreso', 2, '2026-11-07 11:00:00', 'Venta #125', 125);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (125, 'tarjeta', 217000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (14, 'venta', 0, '2026-11-07 11:00:00', 'Venta #125');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (126, '2026-11-07 11:45:00', 59000, 'mixto', 'completada', NULL, 14, 'demo-20261107-004');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261107-004', '6fa279a652a2697e2ed29495f27c1b4ff9276a20d760d0501296b75d8a1a8ca5', 'creada', '2026-11-07 11:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (126, 43, 2, 29500, 59000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (43, 'egreso', 2, '2026-11-07 11:45:00', 'Venta #126', 126);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (126, 'efectivo', 29500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (126, 'tarjeta', 29500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (14, 'venta', 29500, '2026-11-07 11:45:00', 'Venta #126');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (127, '2026-11-07 12:30:00', 145000, 'efectivo', 'completada', NULL, 14, 'demo-20261107-005');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261107-005', '89d26be2db333d891508aa804ed5c743dbf25a2352bba095d470c1e6926c98f7', 'creada', '2026-11-07 12:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (127, 30, 2, 38500, 77000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (30, 'egreso', 2, '2026-11-07 12:30:00', 'Venta #127', 127);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (127, 37, 2, 34000, 68000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (37, 'egreso', 2, '2026-11-07 12:30:00', 'Venta #127', 127);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (127, 'efectivo', 145000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (14, 'venta', 145000, '2026-11-07 12:30:00', 'Venta #127');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (128, '2026-11-07 13:15:00', 176000, 'transferencia', 'completada', NULL, 14, 'demo-20261107-006');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261107-006', '1e35d848f75b48b8275473e13e362214b28538a940de51e6001b9a3ce5fe14b4', 'creada', '2026-11-07 13:15:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (128, 17, 1, 36000, 36000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (17, 'egreso', 1, '2026-11-07 13:15:00', 'Venta #128', 128);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (128, 28, 2, 28000, 56000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (28, 'egreso', 2, '2026-11-07 13:15:00', 'Venta #128', 128);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (128, 21, 2, 42000, 84000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (21, 'egreso', 2, '2026-11-07 13:15:00', 'Venta #128', 128);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (128, 'transferencia', 176000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (14, 'venta', 0, '2026-11-07 13:15:00', 'Venta #128');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (129, '2026-11-07 14:00:00', 31000, 'tarjeta', 'completada', NULL, 14, 'demo-20261107-007');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261107-007', 'bf50305b52967dfa8fce91428e02f36fc6e4d8f573822f4ce22aa4aae4ee45dc', 'creada', '2026-11-07 14:00:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (129, 48, 1, 31000, 31000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (48, 'egreso', 1, '2026-11-07 14:00:00', 'Venta #129', 129);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (129, 'tarjeta', 31000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (14, 'venta', 0, '2026-11-07 14:00:00', 'Venta #129');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (130, '2026-11-07 14:45:00', 93000, 'mixto', 'completada', NULL, 14, 'demo-20261107-008');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261107-008', '7f7b45b21d7c6fad7b98e59d6ea1f0975aa24a7a8468523b2c1be00ec181ce20', 'creada', '2026-11-07 14:45:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (130, 48, 1, 31000, 31000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (48, 'egreso', 1, '2026-11-07 14:45:00', 'Venta #130', 130);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (130, 46, 2, 31000, 62000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (46, 'egreso', 2, '2026-11-07 14:45:00', 'Venta #130', 130);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (130, 'efectivo', 46500);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (130, 'tarjeta', 46500);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (14, 'venta', 46500, '2026-11-07 14:45:00', 'Venta #130');
INSERT INTO ventas (id, fecha_hora, total, medio_pago, estado, motivo_anulacion, caja_id, solicitud_id) VALUES (131, '2026-11-07 15:30:00', 95000, 'efectivo', 'completada', NULL, 14, 'demo-20261107-009');
INSERT INTO solicitudes_venta (solicitud_id, contenido_hash, estado, creado_en) VALUES ('demo-20261107-009', 'c6be7b5cb1dd2c3fcc2911e48b3c6ed38028aa04645676e27235c68347e6fde5', 'creada', '2026-11-07 15:30:00');
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (131, 18, 1, 36000, 36000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (18, 'egreso', 1, '2026-11-07 15:30:00', 'Venta #131', 131);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (131, 25, 1, 28000, 28000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (25, 'egreso', 1, '2026-11-07 15:30:00', 'Venta #131', 131);
INSERT INTO detalle_venta (venta_id, variante_id, cantidad, precio_unitario, subtotal) VALUES (131, 47, 1, 31000, 31000);
INSERT INTO movimientos_stock (variante_id, tipo, cantidad, fecha_hora, motivo, venta_id) VALUES (47, 'egreso', 1, '2026-11-07 15:30:00', 'Venta #131', 131);
INSERT INTO pagos_venta (venta_id, medio, importe) VALUES (131, 'efectivo', 95000);
INSERT INTO movimientos_caja (caja_id, tipo, importe, fecha_hora, referencia) VALUES (14, 'venta', 95000, '2026-11-07 15:30:00', 'Venta #131');
UPDATE variantes SET stock_actual=1 WHERE id=1;
UPDATE variantes SET stock_actual=0 WHERE id=2;
UPDATE variantes SET stock_actual=1 WHERE id=3;
UPDATE variantes SET stock_actual=1 WHERE id=4;
UPDATE variantes SET stock_actual=0 WHERE id=5;
UPDATE variantes SET stock_actual=1 WHERE id=6;
UPDATE variantes SET stock_actual=1 WHERE id=7;
UPDATE variantes SET stock_actual=0 WHERE id=8;
UPDATE variantes SET stock_actual=0 WHERE id=9;
UPDATE variantes SET stock_actual=0 WHERE id=10;
UPDATE variantes SET stock_actual=1 WHERE id=11;
UPDATE variantes SET stock_actual=0 WHERE id=12;
UPDATE variantes SET stock_actual=6 WHERE id=13;
UPDATE variantes SET stock_actual=6 WHERE id=14;
UPDATE variantes SET stock_actual=7 WHERE id=15;
UPDATE variantes SET stock_actual=7 WHERE id=16;
UPDATE variantes SET stock_actual=6 WHERE id=17;
UPDATE variantes SET stock_actual=4 WHERE id=18;
UPDATE variantes SET stock_actual=1 WHERE id=19;
UPDATE variantes SET stock_actual=7 WHERE id=20;
UPDATE variantes SET stock_actual=5 WHERE id=21;
UPDATE variantes SET stock_actual=8 WHERE id=22;
UPDATE variantes SET stock_actual=2 WHERE id=23;
UPDATE variantes SET stock_actual=11 WHERE id=24;
UPDATE variantes SET stock_actual=5 WHERE id=25;
UPDATE variantes SET stock_actual=5 WHERE id=26;
UPDATE variantes SET stock_actual=10 WHERE id=27;
UPDATE variantes SET stock_actual=4 WHERE id=28;
UPDATE variantes SET stock_actual=6 WHERE id=29;
UPDATE variantes SET stock_actual=5 WHERE id=30;
UPDATE variantes SET stock_actual=11 WHERE id=31;
UPDATE variantes SET stock_actual=10 WHERE id=32;
UPDATE variantes SET stock_actual=8 WHERE id=33;
UPDATE variantes SET stock_actual=6 WHERE id=34;
UPDATE variantes SET stock_actual=6 WHERE id=35;
UPDATE variantes SET stock_actual=12 WHERE id=36;
UPDATE variantes SET stock_actual=8 WHERE id=37;
UPDATE variantes SET stock_actual=10 WHERE id=38;
UPDATE variantes SET stock_actual=12 WHERE id=39;
UPDATE variantes SET stock_actual=9 WHERE id=40;
UPDATE variantes SET stock_actual=10 WHERE id=41;
UPDATE variantes SET stock_actual=7 WHERE id=42;
UPDATE variantes SET stock_actual=7 WHERE id=43;
UPDATE variantes SET stock_actual=2 WHERE id=44;
UPDATE variantes SET stock_actual=6 WHERE id=45;
UPDATE variantes SET stock_actual=6 WHERE id=46;
UPDATE variantes SET stock_actual=8 WHERE id=47;
UPDATE variantes SET stock_actual=8 WHERE id=48;
COMMIT;
