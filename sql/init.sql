create schema core;
create schema mediacion;

CREATE TABLE core.persona (
  id                       SERIAL NOT NULL, 
  nombre                   varchar NOT NULL, 
  apellido_paterno         varchar, 
  apellido_materno         varchar, 
  CURP                     varchar(20), 
  RFC                      varchar, 
  sexo                     varchar(1), 
  email                    varchar, 
  telefono                 varchar(15), 
  calle                    varchar, 
  CP                       varchar(5), 
  persona_moral            bool DEFAULT 'false', 
  estado_civil             varchar(1), 
  fecha_creacion           timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_creo             varchar(50) NOT NULL, 
  fecha_actualizacion      timestamp, 
  usuario_actualizo        varchar(50), 
  hablante_lengua_distinta bool DEFAULT 'false', 
  PRIMARY KEY (id),
  CONSTRAINT persona_unique UNIQUE (nombre, apellido_paterno, apellido_materno, curp, rfc, email));

  --

  CREATE TABLE core.usuario (
  id                    SERIAL NOT NULL, 
  clave                 varchar(50) NOT NULL UNIQUE, 
  correo_institucional  varchar NOT NULL UNIQUE, 
  passwd              varchar NOT NULL, 
  estatus               int2 DEFAULT 0 NOT NULL, 
  fecha_creacion        timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_creo          varchar(100) NOT NULL, 
  fecha_actualizacion   timestamp, 
  usuario_actualizacion varchar(100), 
  persona_id            int4 NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE core.modulo (
  id           SERIAL NOT NULL, 
  clave        varchar(20) NOT NULL UNIQUE, 
  descripcion  varchar, 
  estatus      int2 DEFAULT 1, 
  modulo_padre int4 NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE core.rol_modulo_permiso (
  rol_id     int4 NOT NULL, 
  permiso_id int4 NOT NULL, 
  modulo_id  int4 NOT NULL, 
  estatus    int2 DEFAULT 1 NOT NULL, 
  CONSTRAINT rol_permiso_modulo_pk 
    PRIMARY KEY (rol_id, permiso_id, modulo_id));

--

CREATE TABLE core.rol (
  id          SERIAL NOT NULL, 
  clave       varchar(50) NOT NULL UNIQUE, 
  descripcion varchar, 
  activo bool DEFAULT true, 
  PRIMARY KEY (id));

--

CREATE TABLE core.permiso (
  id          SERIAL NOT NULL, 
  clave       int4 NOT NULL UNIQUE, 
  descripcion varchar, 
  activo bool DEFAULT true, 
  PRIMARY KEY (id));

--

CREATE TABLE core.rol_usuario (
  usuario_id          int4 NOT NULL, 
  rol_id              int4 NOT NULL, 
  estatus             int2 DEFAULT 1 NOT NULL, 
  fecha_creacion      timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_creo        varchar(50) NOT NULL, 
  fecha_actualizacion timestamp DEFAULT CURRENT_TIMESTAMP, 
  usuario_actualizo   varchar(50), 
  usuariopersona_id   int4, 
  CONSTRAINT usuario_rol_PK 
    PRIMARY KEY (usuario_id, rol_id));

--

CREATE TABLE core.formato(
  id          SERIAL NOT NULL, 
  clave       varchar(50) NOT NULL, 
  descripcion varchar NOT NULL, 
  version     varchar(10) NOT NULL, 
  activo bool DEFAULT true, 
  PRIMARY KEY (id), 
  CONSTRAINT clave_version_unique 
    UNIQUE (clave, version));

--

CREATE TABLE core.tipo_identificacion (
  id          SERIAL NOT NULL, 
  clave       varchar(50) NOT NULL, 
  descripcion varchar NOT NULL, 
  activo bool DEFAULT true, 
  PRIMARY KEY (id));

--

CREATE TABLE core.area (
  id          SERIAL NOT NULL, 
  clave       varchar(50) NOT NULL UNIQUE, 
  descripcion varchar NOT NULL, 
  estatus     int2 DEFAULT 1, 
  operativa   bool DEFAULT 'false' NOT NULL, 
  sede_id     int4 NOT NULL, 
  responsable int4 NOT NULL, 
  area_padre  int4 NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE core.materia (
  id          SERIAL NOT NULL, 
  clave       varchar(50) NOT NULL UNIQUE, 
  descripcion varchar NOT NULL, 
  activo      bool DEFAULT 'true' NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE core.juzgado (
  id           SERIAL NOT NULL, 
  clave        varchar(50) NOT NULL UNIQUE, 
  nombre       varchar NOT NULL, 
  materia_id   int4 NOT NULL, 
  tipo_juzgado int4 NOT NULL, 
  sede_id      int4 NOT NULL, 
  estatus      int2 DEFAULT 1 NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE core.tipo_juzgado (
  id          SERIAL NOT NULL, 
  clave       varchar(50) NOT NULL UNIQUE, 
  descripcion varchar NOT NULL, 
  activo bool DEFAULT true, 
  PRIMARY KEY (id));

--

CREATE TABLE core.sede (
  id           SERIAL NOT NULL, 
  clave        varchar(50) NOT NULL UNIQUE, 
  nombre       varchar NOT NULL, 
  estatus      int2 DEFAULT 1 NOT NULL, 
  direccion    int4 NOT NULL, 
  cp           int4 NOT NULL, 
  municipio_id int4 NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE core.clasificacion_persona (
  id          SERIAL NOT NULL, 
  clave       varchar(50) NOT NULL UNIQUE, 
  Descripcion int4 NOT NULL, 
  activo bool DEFAULT true, 
  PRIMARY KEY (id));

--

CREATE TABLE core.detalle_persona (
  persona_id       int4 NOT NULL, 
  clasificacion_id int4 NOT NULL, 
  fecha_creacion   timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  CONSTRAINT persona_clasificacion_PK
    PRIMARY KEY (persona_id, clasificacion_id));

--

CREATE TABLE core.archivo (
  id             SERIAL NOT NULL, 
  nombre         varchar NOT NULL, 
  tipo           varchar(50) NOT NULL, 
  data           bytea NOT NULL, 
  fecha_creacion timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_creo   varchar(50) NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE core.estado (
  id     SERIAL NOT NULL, 
  num    int4 NOT NULL UNIQUE, 
  clave  varchar(10) NOT NULL UNIQUE, 
  nombre varchar NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE core.municipio (
  id        SERIAL NOT NULL, 
  num       int4 NOT NULL, 
  clave     varchar NOT NULL UNIQUE, 
  nombre    varchar, 
  estatus   int2 DEFAULT 1, 
  estado_id int4 NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE mediacion.asesoria (
  id                  SERIAL NOT NULL, 
  fecha               timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_creo        varchar(50) NOT NULL, 
  persona_atendida_id int4 NOT NULL, 
  materia_id          int4 NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE mediacion.solicitud (
  id                    SERIAL NOT NULL, 
  folio                 varchar(100) NOT NULL UNIQUE, 
  fecha_solicitud       date DEFAULT CURRENT_DATE NOT NULL, 
  usuario_persona_id    int4 NOT NULL, 
  invitado_persona_id   int4 NOT NULL, 
  fecha_sesion          timestamp NOT NULL, 
  es_mediable           bool DEFAULT 'true' NOT NULL, 
  canalizado            bool DEFAULT 'false' NOT NULL, 
  descripcion_conflicto text NOT NULL, 
  materia_id            int4 NOT NULL, 
  asesoria_id           int4 NOT NULL, 
  tipo_apertura_id      int4 NOT NULL, 
  tipo_cierre_id        int4 NOT NULL, 
  fecha_creacion        timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_creo          varchar(50) NOT NULL, 
  fecha_actualizacion   timestamp, 
  usuario_actualizo     varchar(50), 
  PRIMARY KEY (id));

--

CREATE TABLE mediacion.asistencia (
  id serial4 NOT NULL,
  solicitud_id        int4 NOT NULL, 
  sesion_mediacion_id int4 NOT NULL, 
  fecha_asistencia    date DEFAULT CURRENT_DATE NOT NULL, 
  asiste_usuario      bool DEFAULT 'true' NOT NULL, 
  asiste_invitado     bool DEFAULT 'true' NOT NULL, 
  tipo                int2 DEFAULT 1 NOT NULL, 
  acepta_usuario      bool DEFAULT 'true' NOT NULL, 
  acepta_invitado     bool DEFAULT 'true' NOT NULL, 
  fecha_registro      timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_creo        varchar(50) NOT NULL, 
  fecha_actualizacion timestamp, 
  usuario_actualizo   varchar(50),
  PRIMARY KEY (id));

--

CREATE TABLE mediacion.mediador (
  id                  SERIAL NOT NULL, 
  usuario_id          int4 NOT NULL, 
  numero              int4 NOT NULL, 
  certificado         varchar, 
  estatus             int2 DEFAULT 1 NOT NULL, 
  supervisado_por     int4 NOT NULL, 
  fecha_registro      timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_registro    varchar(50) NOT NULL, 
  fecha_actualización timestamp, 
  usuario_actualizo   varchar(50), 
  PRIMARY KEY (id));

--

CREATE TABLE mediacion.fase_mediacion (
  id          SERIAL NOT NULL, 
  secuencia   int2 NOT NULL, 
  clave       varchar(20) NOT NULL, 
  descripcion varchar NOT NULL, 
  activo      bool DEFAULT 'false' NOT NULL, 
  PRIMARY KEY (id));

--

CREATE TABLE mediacion.formato_fase (
  fase_id    int4 NOT NULL, 
  formato_id int4 NOT NULL, 
  activo     bool DEFAULT 'true' NOT NULL, 
  opcional   bool DEFAULT 'false' NOT NULL, 
  CONSTRAINT formato_fase_pk PRIMARY KEY (fase_id, formato_id));

--

CREATE TABLE mediacion.expediente (
  id                     SERIAL NOT NULL, 
  folio                  varchar(100) NOT NULL UNIQUE, 
  fecha_registro         timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  mediador_id            int4 NOT NULL, 
  solicitud_id           int4 NOT NULL, 
  es_mediable            bool DEFAULT 'true' NOT NULL, 
  hay_acuerdo            bool NOT NULL, 
  asistencia_psicologica bool DEFAULT 'false', 
  asistencia_juridica    bool DEFAULT 'false', 
  estatus                int2 DEFAULT 1, 
  PRIMARY KEY (id));

--

CREATE TABLE mediacion.sesion_mediacion (
  id                  SERIAL NOT NULL, 
  expediente_id       int4 NOT NULL, 
  numero              int2, 
  fecha_sesion        timestamp NOT NULL, 
  observaciones       text, 
  fecha_creacion      timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_creo        varchar(50) NOT NULL, 
  fecha_actualizacion timestamp DEFAULT CURRENT_TIMESTAMP, 
  usuario_actualizo   int4, 
  PRIMARY KEY (id));

--

CREATE TABLE mediacion.acuerdo (
  id                   SERIAL NOT NULL, 
  expediente_id        int4 NOT NULL, 
  fecha_firma          timestamp NOT NULL, 
  aprobado             bool DEFAULT 'false', 
  no_mediable          bool DEFAULT 'false' NOT NULL, 
  fecha_envio_juridico timestamp NOT NULL, 
  fecha_vobo           timestamp NOT NULL, 
  estatus              int2 DEFAULT 0 NOT NULL, 
  fecha_creacion       timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_creo         varchar(50) NOT NULL, 
  fecha_actualizacion  timestamp, 
  usuario_actualizo    varchar(50), 
  PRIMARY KEY (id));

--

CREATE TABLE mediacion.revision_acuerdo (
  acuerdo_id         int4 NOT NULL, 
  usuario_id_revisor int4, 
  fecha_asignacion   timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  fecha_revision     timestamp NOT NULL, 
  archivo_id         int4 NOT NULL, 
  estatus            int2 DEFAULT 0 NOT NULL, 
  observaciones      text,
  CONSTRAINT revision_acuerdo_pk PRIMARY KEY (acuerdo_id, usuario_id_revisor, archivo_id));

--

CREATE TABLE mediacion.tipo_apertura (
  id          SERIAL NOT NULL, 
  clave       varchar(10) NOT NULL UNIQUE, 
  descripcion varchar NOT NULL, 
  activo bool DEFAULT true, 
  PRIMARY KEY (id));

--

CREATE TABLE mediacion.solicitud_electonica (
  solicitud_id   int4 NOT NULL, 
  url            varchar NOT NULL, 
  fecha_creacion timestamp DEFAULT CURRENT_TIMESTAMP,
  num_sesion int2 NOT NULL,  
  CONSTRAINT solicitud_electonica_pk PRIMARY KEY (solicitud_id, num_sesion)
);

--

CREATE TABLE mediacion.solicitud_juzgado (
  solicitud_id     int4 NOT NULL, 
  juzgado_id       int4 NOT NULL, 
  persona_id_turno int4, 
  fecha_creacion   timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL,
  CONSTRAINT solicitud_juzgado_pk PRIMARY KEY (solicitud_id, juzgado_id)
);

--

CREATE TABLE mediacion.solicitud_archivo (
  solicitud_id        int4 NOT NULL, 
  formato_id          int4 NOT NULL, 
  archivo_id          int4 NOT NULL, 
  estatus             int4, 
  fecha_creacion      timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  usuario_creo        varchar(50) NOT NULL, 
  fecha_actualizacion timestamp, 
  usuario_actualizo   varchar(50),
  CONSTRAINT solicitud_archivo_pk PRIMARY KEY (solicitud_id, formato_id, archivo_id)
); 

--

CREATE TABLE mediacion.detalle_usuario_solicitud (
  solicitud_id           int4 NOT NULL, 
  tipo_identificacion_id int4 NOT NULL, 
  persona_id             int4 NOT NULL, 
  numero_identificacion  int4 NOT NULL, 
  fecha_creacion         timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, 
  CONSTRAINT detalle_usuario_solicitud_pk PRIMARY KEY (solicitud_id, tipo_identificacion_id, persona_id)
);

--

CREATE TABLE mediacion.tipo_cierre (
  id          SERIAL NOT NULL, 
  clave       varchar(10) NOT NULL UNIQUE, 
  descripcion varchar NOT NULL, 
  activo      bool DEFAULT true NOT NULL, 
  PRIMARY KEY (id)); 

-- FOREIGN KEYS --

ALTER TABLE core.usuario ADD FOREIGN KEY (persona_id) REFERENCES core.persona (id);
ALTER TABLE core.modulo ADD FOREIGN KEY (modulo_padre) REFERENCES core.modulo (id);
ALTER TABLE core.rol_modulo_permiso ADD FOREIGN KEY (rol_id) REFERENCES core.rol (id);
ALTER TABLE core.rol_modulo_permiso ADD FOREIGN KEY (permiso_id) REFERENCES core.permiso (id);
ALTER TABLE core.rol_modulo_permiso ADD FOREIGN KEY (modulo_id) REFERENCES core.modulo (id);
ALTER TABLE core.rol_usuario ADD FOREIGN KEY (usuario_id) REFERENCES core.usuario (id);
ALTER TABLE core.rol_usuario ADD FOREIGN KEY (rol_id) REFERENCES core.rol (id);
ALTER TABLE core.area ADD FOREIGN KEY (area_padre) REFERENCES core.area (id);
ALTER TABLE core.area ADD FOREIGN KEY (sede_id) REFERENCES core.sede (id);
ALTER TABLE core.area ADD FOREIGN KEY (responsable) REFERENCES core.persona (id);
ALTER TABLE core.juzgado ADD FOREIGN KEY (tipo_juzgado) REFERENCES core.Tipo_juzgado (id);
ALTER TABLE core.juzgado ADD FOREIGN KEY (sede_id) REFERENCES core.sede (id);
ALTER TABLE core.juzgado ADD FOREIGN KEY (materia_id) REFERENCES core.materia (id);
ALTER TABLE core.municipio ADD FOREIGN KEY (estado_id) REFERENCES core.estado (id);
ALTER TABLE core.sede ADD FOREIGN KEY (municipio_id) REFERENCES core.municipio (id);
ALTER TABLE core.detalle_persona ADD FOREIGN KEY (persona_id) REFERENCES core.persona (id);
ALTER TABLE core.detalle_persona ADD FOREIGN KEY (clasificacion_id) REFERENCES core.clasificacion_persona (id);
ALTER TABLE mediacion.solicitud ADD FOREIGN KEY (asesoria_id) REFERENCES mediacion.asesoria (id);
ALTER TABLE mediacion.solicitud ADD FOREIGN KEY (materia_id) REFERENCES core.materia (id);
ALTER TABLE mediacion.solicitud ADD FOREIGN KEY (tipo_apertura_id) REFERENCES mediacion.Tipo_Apertura (id);
ALTER TABLE mediacion.solicitud ADD FOREIGN KEY (tipo_cierre_id) REFERENCES mediacion.Tipo_cierre (id);
ALTER TABLE mediacion.asistencia ADD FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud (id);
ALTER TABLE mediacion.asistencia ADD FOREIGN KEY (sesion_mediacion_id) REFERENCES mediacion.sesion_mediacion (id);
ALTER TABLE mediacion.mediador ADD FOREIGN KEY (supervisado_por) REFERENCES mediacion.mediador (id);
ALTER TABLE mediacion.mediador ADD FOREIGN KEY (usuario_id) REFERENCES core.persona (id);
ALTER TABLE mediacion.formato_fase ADD FOREIGN KEY (fase_id) REFERENCES mediacion.fase_mediacion (id);
ALTER TABLE mediacion.formato_fase ADD FOREIGN KEY (formato_id) REFERENCES core.formato(id);
ALTER TABLE mediacion.expediente ADD FOREIGN KEY (mediador_id) REFERENCES mediacion.mediador (id);
ALTER TABLE mediacion.expediente ADD FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud (id);
ALTER TABLE mediacion.sesion_mediacion ADD FOREIGN KEY (expediente_id) REFERENCES mediacion.expediente (id);
ALTER TABLE mediacion.acuerdo ADD FOREIGN KEY (expediente_id) REFERENCES mediacion.expediente (id);
ALTER TABLE mediacion.revision_acuerdo ADD FOREIGN KEY (acuerdo_id) REFERENCES mediacion.acuerdo (id);
ALTER TABLE mediacion.solicitud_electonica ADD FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud (id);
ALTER TABLE mediacion.solicitud_juzgado ADD FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud (id);
ALTER TABLE mediacion.solicitud_juzgado ADD FOREIGN KEY (juzgado_id) REFERENCES core.juzgado (id);
ALTER TABLE mediacion.solicitud_archivo ADD FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud (id);
ALTER TABLE mediacion.solicitud_archivo ADD FOREIGN KEY (archivo_id) REFERENCES core.archivo (id);
ALTER TABLE mediacion.solicitud_archivo ADD FOREIGN KEY (formato_id) REFERENCES core.formato(id);
ALTER TABLE mediacion.detalle_usuario_solicitud ADD FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud (id);
ALTER TABLE mediacion.detalle_usuario_solicitud ADD FOREIGN KEY (tipo_identificacion_id) REFERENCES core.Tipo_identificacion (id);