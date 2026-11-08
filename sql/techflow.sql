-- Instalacion inicial: detener si techflow ya existe. No elimina datos.
CREATE DATABASE techflow
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE techflow;

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

INSERT INTO categorias (nombre)
VALUES
    ('Remeras'),
    ('Pantalones'),
    ('Abrigos');

INSERT INTO proveedores (nombre, telefono, email)
VALUES
    ('Proveedor local', '342-555-0101', 'ventas@proveedor.local');

INSERT INTO talles (nombre)
VALUES
    ('XS'),
    ('S'),
    ('M'),
    ('L'),
    ('XL');

INSERT INTO colores (nombre)
VALUES
    ('Negro'),
    ('Blanco'),
    ('Azul');

INSERT INTO productos (
    nombre,
    descripcion,
    categoria_id,
    proveedor_id,
    precio,
    activo
)
VALUES
    ('Remera basica', 'Remera de algodon de uso diario', 1, 1, 15000.00, TRUE),
    ('Jean recto', 'Jean clasico', 2, 1, 32000.00, TRUE),
    ('Buzo liviano', 'Buzo para media estacion', 3, 1, 28000.00, TRUE);

INSERT INTO variantes (
    producto_id,
    talle_id,
    color_id,
    codigo,
    stock_actual,
    stock_minimo
)
VALUES
    (1, 3, 1, 'REM-BAS-M-NEG', 12, 3),
    (1, 4, 2, 'REM-BAS-L-BLA', 8, 2),
    (2, 3, 3, 'JEA-REC-M-AZU', 5, 2),
    (3, 3, 1, 'BUZ-LIV-M-NEG', 4, 2);

INSERT INTO caja (
    fecha_apertura,
    saldo_inicial,
    estado
)
VALUES
    (NOW(), 0, 'abierta');

CREATE USER IF NOT EXISTS 'techflow_app'@'localhost'
    IDENTIFIED BY 'techflow';

CREATE USER IF NOT EXISTS 'techflow_app'@'127.0.0.1'
    IDENTIFIED BY 'techflow';

GRANT SELECT, INSERT, UPDATE, DELETE
ON techflow.*
TO 'techflow_app'@'localhost';

GRANT SELECT, INSERT, UPDATE, DELETE
ON techflow.*
TO 'techflow_app'@'127.0.0.1';

FLUSH PRIVILEGES;
