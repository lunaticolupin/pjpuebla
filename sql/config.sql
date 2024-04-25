-- Crear un un usuario o rol  --
create user pjpuebla with password 'PJPu3bl4#2024';

-- Asignar el privilegio para crear base de datos --
ALTER ROLE pjpuebla NOSUPERUSER CREATEDB NOCREATEROLE INHERIT LOGIN NOREPLICATION NOBYPASSRLS;

-- Crear la base de datos --
create database pjpuebla

-- Cambiar el propietario de la base de datos --
ALTER DATABASE pjpuebla OWNER TO pjpuebla;

