
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