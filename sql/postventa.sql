USE techflow;

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