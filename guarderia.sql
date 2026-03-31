
-- PARTE PRINCIPAL


-- TABLAS
CREATE TABLE ninos (id SERIAL PRIMARY KEY, nombre VARCHAR(100), fecha_nacimiento DATE, genero VARCHAR(10));
CREATE TABLE padres (id SERIAL PRIMARY KEY, nombre VARCHAR(100), telefono VARCHAR(20), direccion TEXT);
CREATE TABLE nino_padre (id SERIAL PRIMARY KEY, nino_id INT REFERENCES ninos(id), padre_id INT REFERENCES padres(id));
CREATE TABLE empleados (id SERIAL PRIMARY KEY, nombre VARCHAR(100), cargo VARCHAR(50), telefono VARCHAR(20));
CREATE TABLE aulas (id SERIAL PRIMARY KEY, nombre VARCHAR(50), capacidad INT);
CREATE TABLE inscripciones (id SERIAL PRIMARY KEY, nino_id INT REFERENCES ninos(id), aula_id INT REFERENCES aulas(id), fecha_inscripcion DATE);
CREATE TABLE pagos (id SERIAL PRIMARY KEY, nino_id INT REFERENCES ninos(id), monto DECIMAL(10,2), fecha_pago DATE);

-- DATOS
INSERT INTO ninos (nombre, fecha_nacimiento, genero)
SELECT 'Nino ' || generate_series,
DATE '2018-01-01' + (generate_series || ' days')::interval,
CASE WHEN generate_series % 2 = 0 THEN 'Masculino' ELSE 'Femenino' END
FROM generate_series(1,100);

INSERT INTO padres (nombre, telefono, direccion)
SELECT 'Padre ' || generate_series, '809000' || generate_series, 'Santo Domingo'
FROM generate_series(1,100);

INSERT INTO nino_padre (nino_id, padre_id)
SELECT id, id FROM ninos;

INSERT INTO aulas (nombre, capacidad)
VALUES ('Aula A',20),('Aula B',25),('Aula C',30);

INSERT INTO inscripciones (nino_id, aula_id, fecha_inscripcion)
SELECT id, (id % 3)+1, CURRENT_DATE FROM ninos;

INSERT INTO pagos (nino_id, monto, fecha_pago)
SELECT id, (RANDOM()*5000+1000)::DECIMAL(10,2), CURRENT_DATE FROM ninos;

-- CONSULTAS
SELECT * FROM ninos;
SELECT COUNT(*) FROM ninos;
SELECT n.nombre, p.monto FROM ninos n JOIN pagos p ON n.id = p.nino_id;


-- TRANSACCIONES
BEGIN;
INSERT INTO ninos (nombre, fecha_nacimiento, genero)
VALUES ('Transaccion OK','2020-01-01','Masculino');
COMMIT;

BEGIN;
INSERT INTO ninos (nombre, fecha_nacimiento, genero)
VALUES ('Transaccion FAIL','2020-01-01','Masculino');
ROLLBACK;

-- INDEXACIÓN
EXPLAIN ANALYZE SELECT * FROM pagos WHERE nino_id = 10;

CREATE INDEX idx_pagos_nino_id ON pagos(nino_id);

EXPLAIN ANALYZE SELECT * FROM pagos WHERE nino_id = 10;

-- SERVIDOR REMOTO 

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE SERVER servidor_remoto
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'guarderia-postgres-remote', dbname 'guarderia_remota', port '5432');

CREATE USER MAPPING FOR admin
SERVER servidor_remoto
OPTIONS (user 'admin', password '1234');

IMPORT FOREIGN SCHEMA public
LIMIT TO (empleados_remotos)
FROM SERVER servidor_remoto INTO public;

SELECT * FROM empleados_remotos;

-- PARALELISMO
SET max_parallel_workers_per_gather = 4;
EXPLAIN ANALYZE SELECT SUM(monto) FROM pagos;

-- FUNCIÓN
CREATE OR REPLACE FUNCTION total_pagado_nino(nino INT)
RETURNS DECIMAL AS $$
BEGIN
  RETURN (SELECT SUM(monto) FROM pagos WHERE nino_id = nino);
END;
$$ LANGUAGE plpgsql;

-- PROCEDIMIENTO
CREATE OR REPLACE PROCEDURE registrar_pago(nino INT, monto DECIMAL)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO pagos(nino_id, monto, fecha_pago)
  VALUES (nino, monto, CURRENT_DATE);
END;
$$;

-- TRIGGER
CREATE OR REPLACE FUNCTION validar_pago()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.monto <= 0 THEN
    RAISE EXCEPTION 'Monto inválido';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_validar_pago
BEFORE INSERT ON pagos
FOR EACH ROW
EXECUTE FUNCTION validar_pago();
