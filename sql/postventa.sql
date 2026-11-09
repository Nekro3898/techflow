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
