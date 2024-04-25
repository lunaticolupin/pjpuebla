# Guía ráoida para el uso de Postgres desde la consola

# Conexión 
# el parametro -W es para introducir el password desde la consola
# el parametro -d es opcional
$ psql -U usuario -h servidor -W -d base_datos

# Importar script
$ psql -U usuario -h servidor -W -d base_datos < /ruta/archivo/script.sql


# Crear un respaldo
$ pg_dump -U usuario base_datos -n esquema1,esquema2,esquemaN -h servidor -W > script.sql

# Listar las bases de datos

posrgres=# \l

# Listar esquemas de la BD
postgres=# \dn

# Listar los objetos de la BD
postgres=# \d