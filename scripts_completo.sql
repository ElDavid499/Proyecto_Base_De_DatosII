--Scripts completo sobre el proyecto
 1. CREACIÓN DE TABLAS


CREATE TABLE generos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

CREATE TABLE artistas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    fecha_creacion DATE,
    estado BOOLEAN DEFAULT TRUE
);

CREATE TABLE albumes (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    artista_id INT REFERENCES artistas(id),
    fecha_lanzamiento DATE
);

CREATE TABLE canciones (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    duracion INTERVAL,
    genero_id INT REFERENCES generos(id),
    album_id INT REFERENCES albumes(id),
    artista_id INT REFERENCES artistas(id)
);

CREATE TABLE tipos_suscripcion (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50),
    descripcion TEXT
);

CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(50) NOT NULL,
    correo VARCHAR(100),
    tipo_suscripcion_id INT REFERENCES tipos_suscripcion(id)
);

CREATE TABLE playlists (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    usuario_id INT REFERENCES usuarios(id),
    publica BOOLEAN,
    fecha_creacion DATE DEFAULT CURRENT_DATE
);

CREATE TABLE playlist_canciones (
    playlist_id INT REFERENCES playlists(id),
    cancion_id INT REFERENCES canciones(id),
    PRIMARY KEY (playlist_id, cancion_id)
);

CREATE TABLE historial_reproduccion (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    cancion_id INT REFERENCES canciones(id),
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE canciones_favoritas (
    usuario_id INT REFERENCES usuarios(id),
    cancion_id INT REFERENCES canciones(id),
    PRIMARY KEY (usuario_id, cancion_id)
);


 2. INSERCIÓN DE DATOS


INSERT INTO generos (nombre) VALUES ('Pop'), ('Rock'), ('Reggaeton'), ('Jazz'), ('Clásica');

INSERT INTO artistas (nombre, descripcion, fecha_creacion) VALUES
('Shakira', 'Pop latino', '1990-01-01'),
('Bad Bunny', 'Reggaeton puertorriqueño', '2016-03-01'),
('Soda Stereo', 'Rock argentino', '1982-05-01'),
('Adele', 'Soul/pop', '2008-01-01'),
('Queen', 'Rock británico', '1970-01-01');

INSERT INTO albumes (titulo, artista_id, fecha_lanzamiento) VALUES
('El Dorado', 1, '2017-05-26'),
('YHLQMDLG', 2, '2020-02-29'),
('Doble Vida', 3, '1995-01-01'),
('25', 4, '2015-11-20'),
('A Night at the Opera', 5, '1975-11-21');

INSERT INTO canciones (titulo, duracion, genero_id, album_id, artista_id) VALUES
('Chantaje', '00:03:17', 1, 1, 1),
('La Difícil', '00:02:44', 3, 2, 2),
('De Música Ligera', '00:03:30', 2, 3, 3),
('Hello', '00:04:55', 1, 4, 4),
('Bohemian Rhapsody', '00:05:55', 2, 5, 5);

INSERT INTO tipos_suscripcion (nombre, descripcion) VALUES
('Gratuita', 'Acceso limitado con anuncios'),
('Premium', 'Acceso total sin anuncios');

INSERT INTO usuarios (nombre_usuario, correo, tipo_suscripcion_id) VALUES
('usuario1', 'user1@mail.com', 1),
('usuario2', 'user2@mail.com', 2),
('usuario3', 'user3@mail.com', 1),
('usuario4', 'user4@mail.com', 2),
('usuario5', 'user5@mail.com', 2);

INSERT INTO playlists (nombre, usuario_id, publica) VALUES
('Mi Pop Favorito', 1, TRUE),
('Rock Legendario', 2, TRUE),
('Relax Jazz', 3, FALSE),
('Éxitos 2020', 4, TRUE),
('Clásicas Inolvidables', 5, FALSE);

INSERT INTO playlist_canciones (playlist_id, cancion_id) VALUES
(1, 1), (2, 3), (3, 4), (4, 2), (5, 5);

INSERT INTO historial_reproduccion (usuario_id, cancion_id) VALUES
(1, 1), (1, 2), (2, 3), (3, 4), (4, 5);

INSERT INTO canciones_favoritas (usuario_id, cancion_id) VALUES
(1, 1), (2, 3), (3, 4), (4, 5), (5, 2);


 3. ÍNDICES


CREATE INDEX idx_canciones_titulo ON canciones(titulo);
CREATE INDEX idx_canciones_artista ON canciones(artista_id);
CREATE INDEX idx_canciones_album ON canciones(album_id);
CREATE INDEX idx_canciones_genero ON canciones(genero_id);
CREATE INDEX idx_playlists_usuario ON playlists(usuario_id);
CREATE INDEX idx_historial_usuario ON historial_reproduccion(usuario_id);


 4. VISTAS RELEVANTES


CREATE VIEW canciones_mas_reproducidas AS
SELECT c.titulo, COUNT(*) AS reproducciones
FROM historial_reproduccion h
JOIN canciones c ON c.id = h.cancion_id
GROUP BY c.titulo
ORDER BY reproducciones DESC;

CREATE VIEW historial_usuario AS
SELECT u.nombre_usuario, c.titulo, h.fecha_hora
FROM historial_reproduccion h
JOIN usuarios u ON h.usuario_id = u.id
JOIN canciones c ON h.cancion_id = c.id;

CREATE VIEW playlists_publicas_populares AS
SELECT p.nombre, u.nombre_usuario, COUNT(pc.cancion_id) AS total_canciones
FROM playlists p
JOIN usuarios u ON u.id = p.usuario_id
JOIN playlist_canciones pc ON p.id = pc.playlist_id
WHERE p.publica = TRUE
GROUP BY p.nombre, u.nombre_usuario
ORDER BY total_canciones DESC;

CREATE VIEW artistas_con_mas_canciones AS
SELECT a.nombre, COUNT(c.id) AS cantidad_canciones
FROM artistas a
JOIN canciones c ON a.id = c.artista_id
GROUP BY a.nombre
ORDER BY cantidad_canciones DESC;

CREATE VIEW canciones_favoritas_usuarios AS
SELECT u.nombre_usuario, c.titulo
FROM canciones_favoritas cf
JOIN usuarios u ON u.id = cf.usuario_id
JOIN canciones c ON c.id = cf.cancion_id;


 5. STORED PROCEDURES

CREATE OR REPLACE PROCEDURE crear_artista(nombre TEXT, descripcion TEXT, fecha_creacion DATE)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO artistas(nombre, descripcion, fecha_creacion) VALUES (nombre, descripcion, fecha_creacion);
END;
$$;

CREATE OR REPLACE PROCEDURE actualizar_album(album_id INT, nuevo_titulo TEXT)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE albumes SET titulo = nuevo_titulo WHERE id = album_id;
END;
$$;


 6. TRIGGERS AUDITORÍA


CREATE OR REPLACE FUNCTION registrar_reproduccion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historial_reproduccion(usuario_id, cancion_id, fecha_hora)
    VALUES (NEW.usuario_id, NEW.cancion_id, CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_reproduccion
AFTER INSERT ON historial_reproduccion
FOR EACH ROW EXECUTE FUNCTION registrar_reproduccion();


 7. FUNCIONES ÚTILES


CREATE OR REPLACE FUNCTION duracion_total_playlist(playlist_id INT)
RETURNS INTERVAL AS $$
BEGIN
    RETURN (
        SELECT SUM(c.duracion)
        FROM playlist_canciones pc
        JOIN canciones c ON c.id = pc.cancion_id
        WHERE pc.playlist_id = playlist_id
    );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION reproducciones_usuario(usuario_id INT, cancion_id INT)
RETURNS INT AS $$
BEGIN
    RETURN (
        SELECT COUNT(*) FROM historial_reproduccion
        WHERE usuario_id = usuario_id AND cancion_id = cancion_id
    );
END;
$$ LANGUAGE plpgsql;

 8. CONSULTAS Y SUBCONSULTAS


-- INNER JOIN
SELECT u.nombre_usuario, c.titulo
FROM historial_reproduccion h
INNER JOIN usuarios u ON h.usuario_id = u.id
INNER JOIN canciones c ON h.cancion_id = c.id;

-- LEFT JOIN
SELECT u.nombre_usuario, p.nombre
FROM usuarios u
LEFT JOIN playlists p ON u.id = p.usuario_id;

-- RIGHT JOIN
SELECT p.nombre, u.nombre_usuario
FROM playlists p
RIGHT JOIN usuarios u ON u.id = p.usuario_id;

-- Subconsulta
SELECT nombre_usuario FROM usuarios
WHERE id IN (SELECT usuario_id FROM canciones_favoritas WHERE cancion_id = 1);

 9. CTEs


WITH reproducciones_por_usuario AS (
    SELECT usuario_id, COUNT(*) AS total
    FROM historial_reproduccion
    GROUP BY usuario_id
)
SELECT u.nombre_usuario, r.total
FROM usuarios u
JOIN reproducciones_por_usuario r ON u.id = r.usuario_id;

WITH canciones_por_genero AS (
    SELECT genero_id, COUNT(*) AS cantidad
    FROM canciones
    GROUP BY genero_id
)
SELECT g.nombre, cpg.cantidad
FROM generos g
JOIN canciones_por_genero cpg ON g.id = cpg.genero_id;

10. SEGURIDAD


CREATE ROLE usuario_gratuito;
CREATE ROLE usuario_premium;
CREATE ROLE admin_contenido;
CREATE ROLE admin_sistema;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO usuario_gratuito;
GRANT SELECT, INSERT, UPDATE, DELETE ON playlists TO usuario_premium;
GRANT SELECT, INSERT, UPDATE, DELETE ON artistas, albumes, canciones TO admin_contenido;
GRANT ALL PRIVILEGES ON DATABASE postgres TO admin_sistema;

CREATE USER user1 WITH PASSWORD 'pass1';
GRANT usuario_gratuito TO user1;

CREATE USER user2 WITH PASSWORD 'pass2';
GRANT usuario_premium TO user2;
