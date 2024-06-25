--
-- PostgreSQL database dump
--

-- Dumped from database version 14.12 (Ubuntu 14.12-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.12 (Ubuntu 14.12-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: core; Type: SCHEMA; Schema: -; Owner: pjpuebla
--

CREATE SCHEMA core;


ALTER SCHEMA core OWNER TO pjpuebla;

--
-- Name: mediacion; Type: SCHEMA; Schema: -; Owner: pjpuebla
--

CREATE SCHEMA mediacion;


ALTER SCHEMA mediacion OWNER TO pjpuebla;

--
-- Name: curp_registrada(character varying); Type: FUNCTION; Schema: core; Owner: postgres
--

CREATE FUNCTION core.curp_registrada(p_curp character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare existe int;
	begin
		
		if p_curp is null then
			return false;
		end if;
	
		select count (*) into existe from core.persona p where p.curp  = p_curp;
	
		if existe > 0 then
			return true;
		end if;
	
		return false;
	END;
$$;


ALTER FUNCTION core.curp_registrada(p_curp character varying) OWNER TO postgres;

--
-- Name: curp_rfc_registrada(character varying, character varying); Type: FUNCTION; Schema: core; Owner: postgres
--

CREATE FUNCTION core.curp_rfc_registrada(p_curp character varying, p_rfc character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare existe int;
	begin
		existe := 0;
		-- buscar CURP --
		select count (*) into existe from core.persona p where p.curp  = p_curp and p_curp is not null;
	
		if existe > 0 then
			raise notice 'CURP % registrada', p_curp;
			return true;
		end if;
	
		existe := 0;
	
		-- buscar RFC --
		select count (*) into existe from core.persona p where p.rfc  = p_rfc and p_rfc is not null;
	
		if existe > 0 then
			raise notice 'RFC % registrado', p_rfc;
			return true;
		end if;
	
		return false;
	END;
$$;


ALTER FUNCTION core.curp_rfc_registrada(p_curp character varying, p_rfc character varying) OWNER TO postgres;

--
-- Name: nombre_persona(integer); Type: FUNCTION; Schema: core; Owner: postgres
--

CREATE FUNCTION core.nombre_persona(p_persona_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
	DECLARE 
		t_persona core.persona%rowtype;
	BEGIN

		select * from core.persona into t_persona p where p.id = p_persona_id;
	
		if t_persona.id is null then
			return null;
		end if;
	
		if t_persona.persona_moral = true then
			return t_persona.nombre;
		end if;
	
		return format('%s %s %s', t_persona.nombre, t_persona.apellido_paterno, t_persona.apellido_materno);
	END;
$$;


ALTER FUNCTION core.nombre_persona(p_persona_id integer) OWNER TO postgres;

--
-- Name: persona_valid(); Type: FUNCTION; Schema: core; Owner: postgres
--

CREATE FUNCTION core.persona_valid() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin

	
	if old.curp != new.curp and core.curp_rfc_registrada(new.curp, new.rfc) then
		raise exception 'La CURP o RFC esta registrada';
	end if;

	if new.persona_moral = false and new.apellido_paterno is null and new.apellido_materno is null then 
		raise exception 'Los apellidos son requeridos';
	end if;

	if new.persona_moral = true and new.rfc is null then 
		raise exception 'El RFC es requerido';
	end if;

	if (TG_OP = 'UPDATE') then
	
		if new.usuario_actualizo is null then
			raise exception 'El campo usuario_actualizo no puede ser nulo';
		end if;
	
		if new.usuario_creo != old.usuario_creo then
			new.usuario_creo := old.usuario_creo;
		end if;
	
		new.fecha_actualizacion := CURRENT_TIMESTAMP;
	end if;

	if new.usuario_creo is null then
		/*raise exception 'El campo usuario_creo no puede ser nulo';*/
		new.usuario_creo:='SYS';
	end if;

	return new;
end
$$;


ALTER FUNCTION core.persona_valid() OWNER TO postgres;

--
-- Name: foliador(character varying); Type: FUNCTION; Schema: mediacion; Owner: postgres
--

CREATE FUNCTION mediacion.foliador(clave_area character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare folio varchar;
	BEGIN
		select clave_area || '-' || lpad(nextval('mediacion.seq_foliador')::text,4,'0')  ||  '-' || EXTRACT(YEAR FROM CURRENT_DATE) into folio;
	
		return folio;
	END;
$$;


ALTER FUNCTION mediacion.foliador(clave_area character varying) OWNER TO postgres;

--
-- Name: fun_fecha_sesion(); Type: FUNCTION; Schema: mediacion; Owner: postgres
--

CREATE FUNCTION mediacion.fun_fecha_sesion() RETURNS timestamp without time zone
    LANGUAGE plpgsql
    AS $$
	declare t_fecha_sesion timestamp;
	declare ultimo_dia_inhabil date;
	declare siguiente_dia_habil date;
	declare dia_semana int;
    declare num_citas int;
	begin
		
	select extract('dow' from current_date), current_date+1 into dia_semana, siguiente_dia_habil;

	if (dia_semana >=5 ) then
		select current_date + (7-dia_semana) into siguiente_dia_habil;
	end if;
	
	select count(1) into num_citas from mediacion.solicitud s  where fecha_sesion::date = siguiente_dia_habil;

	if (num_citas>3) then
		ultimo_dia_inhabil := siguiente_dia_habil;
	
		select fecha_sesion::date, count(1) into siguiente_dia_habil, num_citas 
		from mediacion.solicitud s 
		where fecha_sesion is not null and fecha_sesion >= current_date and fecha_sesion <= ultimo_dia_inhabil
		group by fecha_sesion::date
		having count(*) <4
		order by fecha_sesion::date limit 1;
	
		if siguiente_dia_habil is null then
			siguiente_dia_habil := ultimo_dia_inhabil+1;
		end if;
		
		ultimo_dia_inhabil := null;
	end if;

	-- Verifica que la fecha selecciona no este en un periodo inhabil
	select dcc.fecha_fin::date into ultimo_dia_inhabil from mediacion.det_config_citas dcc 
	where dcc.config_id = (select id from mediacion.config_citas cc where cc.clave='DI')
	and siguiente_dia_habil between dcc.fecha_inicio::date and dcc.fecha_fin::date;

	if (ultimo_dia_inhabil is not null) then
		siguiente_dia_habil:=ultimo_dia_inhabil+1;
	end if;

	select min(to_timestamp(siguiente_dia_habil ||' '|| valor,'yyyy-mm-dd hh24:mi')::timestamp without time zone) into t_fecha_sesion
	from mediacion.det_config_citas dcc 
	where dcc.config_id = (select id from mediacion.config_citas cc where cc.clave='H')
	and not exists 
	(select * from mediacion.solicitud s where s.fecha_sesion = to_timestamp(siguiente_dia_habil ||' '|| dcc.valor,'yyyy-mm-dd hh24:mi')::timestamp without time zone);

	return t_fecha_sesion;
	END;
$$;


ALTER FUNCTION mediacion.fun_fecha_sesion() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: archivo; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.archivo (
    id integer NOT NULL,
    nombre character varying NOT NULL,
    tipo character varying(50) NOT NULL,
    data bytea NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_creo character varying(50) NOT NULL
);


ALTER TABLE core.archivo OWNER TO pjpuebla;

--
-- Name: archivo_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.archivo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.archivo_id_seq OWNER TO pjpuebla;

--
-- Name: archivo_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.archivo_id_seq OWNED BY core.archivo.id;


--
-- Name: area; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.area (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    descripcion character varying NOT NULL,
    estatus smallint DEFAULT 1,
    operativa boolean DEFAULT false NOT NULL,
    sede_id integer NOT NULL,
    responsable integer,
    area_padre integer,
    telefono character varying,
    correo character varying,
    horario character varying,
    ubicacion character varying,
    puesto character varying
);


ALTER TABLE core.area OWNER TO pjpuebla;

--
-- Name: area_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.area_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.area_id_seq OWNER TO pjpuebla;

--
-- Name: area_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.area_id_seq OWNED BY core.area.id;


--
-- Name: clasificacion_persona; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.clasificacion_persona (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    descripcion integer NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE core.clasificacion_persona OWNER TO pjpuebla;

--
-- Name: clasificacion_persona_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.clasificacion_persona_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.clasificacion_persona_id_seq OWNER TO pjpuebla;

--
-- Name: clasificacion_persona_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.clasificacion_persona_id_seq OWNED BY core.clasificacion_persona.id;


--
-- Name: detalle_persona; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.detalle_persona (
    persona_id integer NOT NULL,
    clasificacion_id integer NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE core.detalle_persona OWNER TO pjpuebla;

--
-- Name: estado; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.estado (
    id integer NOT NULL,
    num integer NOT NULL,
    clave character varying(10) NOT NULL,
    nombre character varying NOT NULL
);


ALTER TABLE core.estado OWNER TO pjpuebla;

--
-- Name: estado_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.estado_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.estado_id_seq OWNER TO pjpuebla;

--
-- Name: estado_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.estado_id_seq OWNED BY core.estado.id;


--
-- Name: formato; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.formato (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    descripcion character varying NOT NULL,
    version character varying(10) NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE core.formato OWNER TO pjpuebla;

--
-- Name: formato_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.formato_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.formato_id_seq OWNER TO pjpuebla;

--
-- Name: formato_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.formato_id_seq OWNED BY core.formato.id;


--
-- Name: instituciones; Type: TABLE; Schema: core; Owner: postgres
--

CREATE TABLE core.instituciones (
    id integer NOT NULL,
    clave character varying NOT NULL,
    nombre character varying NOT NULL,
    direccion character varying,
    tipo character varying,
    activo boolean DEFAULT true,
    contacto character varying
);


ALTER TABLE core.instituciones OWNER TO postgres;

--
-- Name: instituciones_id_seq; Type: SEQUENCE; Schema: core; Owner: postgres
--

CREATE SEQUENCE core.instituciones_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.instituciones_id_seq OWNER TO postgres;

--
-- Name: instituciones_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: postgres
--

ALTER SEQUENCE core.instituciones_id_seq OWNED BY core.instituciones.id;


--
-- Name: juzgado; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.juzgado (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    nombre character varying NOT NULL,
    materia_id integer NOT NULL,
    tipo_juzgado integer NOT NULL,
    sede_id integer NOT NULL,
    estatus smallint DEFAULT 1 NOT NULL
);


ALTER TABLE core.juzgado OWNER TO pjpuebla;

--
-- Name: juzgado_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.juzgado_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.juzgado_id_seq OWNER TO pjpuebla;

--
-- Name: juzgado_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.juzgado_id_seq OWNED BY core.juzgado.id;


--
-- Name: materia; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.materia (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    descripcion character varying NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE core.materia OWNER TO pjpuebla;

--
-- Name: materia_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.materia_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.materia_id_seq OWNER TO pjpuebla;

--
-- Name: materia_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.materia_id_seq OWNED BY core.materia.id;


--
-- Name: modulo; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.modulo (
    id integer NOT NULL,
    clave character varying(20) NOT NULL,
    descripcion character varying,
    estatus smallint DEFAULT 1,
    modulo_padre integer
);


ALTER TABLE core.modulo OWNER TO pjpuebla;

--
-- Name: modulo_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.modulo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.modulo_id_seq OWNER TO pjpuebla;

--
-- Name: modulo_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.modulo_id_seq OWNED BY core.modulo.id;


--
-- Name: municipio; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.municipio (
    id integer NOT NULL,
    num integer NOT NULL,
    clave character varying NOT NULL,
    nombre character varying,
    estatus smallint DEFAULT 1,
    estado_id integer NOT NULL
);


ALTER TABLE core.municipio OWNER TO pjpuebla;

--
-- Name: municipio_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.municipio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.municipio_id_seq OWNER TO pjpuebla;

--
-- Name: municipio_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.municipio_id_seq OWNED BY core.municipio.id;


--
-- Name: permiso; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.permiso (
    id integer NOT NULL,
    clave character varying(4) NOT NULL,
    descripcion character varying,
    activo boolean DEFAULT true
);


ALTER TABLE core.permiso OWNER TO pjpuebla;

--
-- Name: permiso_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.permiso_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.permiso_id_seq OWNER TO pjpuebla;

--
-- Name: permiso_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.permiso_id_seq OWNED BY core.permiso.id;


--
-- Name: persona; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.persona (
    id integer NOT NULL,
    nombre character varying NOT NULL,
    apellido_paterno character varying,
    apellido_materno character varying,
    curp character varying(20),
    rfc character varying(15),
    sexo character varying(1),
    email character varying,
    telefono character varying(15),
    calle character varying,
    cp character varying(5),
    persona_moral boolean DEFAULT false,
    estado_civil character varying(1),
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    usuario_creo character varying(50),
    fecha_actualizacion timestamp without time zone,
    usuario_actualizo character varying(50),
    hablante_lengua_distinta boolean DEFAULT false,
    representante integer,
    celular character varying(15),
    edad smallint,
    ocupacion character varying,
    escolaridad smallint,
    identificacion_id integer,
    num_identificacion character varying
);


ALTER TABLE core.persona OWNER TO pjpuebla;

--
-- Name: persona_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.persona_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.persona_id_seq OWNER TO pjpuebla;

--
-- Name: persona_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.persona_id_seq OWNED BY core.persona.id;


--
-- Name: sede; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.sede (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    nombre character varying NOT NULL,
    estatus smallint DEFAULT 1 NOT NULL,
    direccion character varying NOT NULL,
    cp integer NOT NULL,
    municipio_id integer NOT NULL
);


ALTER TABLE core.sede OWNER TO pjpuebla;

--
-- Name: qry_area_responsable; Type: VIEW; Schema: core; Owner: postgres
--

CREATE VIEW core.qry_area_responsable AS
 SELECT a.id AS area_id,
    a.clave,
    a.descripcion AS unidad,
    ap.descripcion AS superior,
    a.puesto,
    core.nombre_persona(a.responsable) AS responsable,
    s.direccion,
    a.ubicacion,
    s.cp,
    s.nombre AS sede,
    a.telefono,
    a.correo,
    a.horario
   FROM (((core.area a
     LEFT JOIN core.persona p ON ((p.id = a.responsable)))
     LEFT JOIN core.sede s ON ((s.id = a.sede_id)))
     LEFT JOIN core.area ap ON ((ap.id = a.area_padre)));


ALTER TABLE core.qry_area_responsable OWNER TO postgres;

--
-- Name: rol; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.rol (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    descripcion character varying,
    activo boolean DEFAULT true
);


ALTER TABLE core.rol OWNER TO pjpuebla;

--
-- Name: rol_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.rol_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.rol_id_seq OWNER TO pjpuebla;

--
-- Name: rol_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.rol_id_seq OWNED BY core.rol.id;


--
-- Name: rol_modulo_permiso; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.rol_modulo_permiso (
    rol_id integer NOT NULL,
    permiso_id integer NOT NULL,
    modulo_id integer NOT NULL,
    estatus smallint DEFAULT 1 NOT NULL
);


ALTER TABLE core.rol_modulo_permiso OWNER TO pjpuebla;

--
-- Name: rol_usuario; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.rol_usuario (
    usuario_id integer NOT NULL,
    rol_id integer NOT NULL,
    estatus smallint DEFAULT 1 NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_creo character varying(50) NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    usuario_actualizo character varying(50)
);


ALTER TABLE core.rol_usuario OWNER TO pjpuebla;

--
-- Name: sede_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.sede_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.sede_id_seq OWNER TO pjpuebla;

--
-- Name: sede_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.sede_id_seq OWNED BY core.sede.id;


--
-- Name: tipo_identificacion; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.tipo_identificacion (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    descripcion character varying NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE core.tipo_identificacion OWNER TO pjpuebla;

--
-- Name: tipo_identificacion_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.tipo_identificacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.tipo_identificacion_id_seq OWNER TO pjpuebla;

--
-- Name: tipo_identificacion_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.tipo_identificacion_id_seq OWNED BY core.tipo_identificacion.id;


--
-- Name: tipo_juzgado; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.tipo_juzgado (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    descripcion character varying NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE core.tipo_juzgado OWNER TO pjpuebla;

--
-- Name: tipo_juzgado_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.tipo_juzgado_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.tipo_juzgado_id_seq OWNER TO pjpuebla;

--
-- Name: tipo_juzgado_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.tipo_juzgado_id_seq OWNED BY core.tipo_juzgado.id;


--
-- Name: usuario; Type: TABLE; Schema: core; Owner: pjpuebla
--

CREATE TABLE core.usuario (
    id integer NOT NULL,
    clave character varying(50) NOT NULL,
    correo_institucional character varying NOT NULL,
    passwd character varying NOT NULL,
    estatus smallint DEFAULT 0 NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_creo character varying(100) NOT NULL,
    fecha_actualizacion timestamp without time zone,
    usuario_actualizacion character varying(100),
    persona_id integer NOT NULL,
    last_login timestamp without time zone
);


ALTER TABLE core.usuario OWNER TO pjpuebla;

--
-- Name: usuario_id_seq; Type: SEQUENCE; Schema: core; Owner: pjpuebla
--

CREATE SEQUENCE core.usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE core.usuario_id_seq OWNER TO pjpuebla;

--
-- Name: usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: core; Owner: pjpuebla
--

ALTER SEQUENCE core.usuario_id_seq OWNED BY core.usuario.id;


--
-- Name: acuerdo; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.acuerdo (
    id integer NOT NULL,
    expediente_id integer NOT NULL,
    fecha_firma timestamp without time zone NOT NULL,
    aprobado boolean DEFAULT false,
    no_mediable boolean DEFAULT false NOT NULL,
    fecha_envio_juridico timestamp without time zone NOT NULL,
    fecha_vobo timestamp without time zone NOT NULL,
    estatus smallint DEFAULT 0 NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_creo character varying(50) NOT NULL,
    fecha_actualizacion timestamp without time zone,
    usuario_actualizo character varying(50)
);


ALTER TABLE mediacion.acuerdo OWNER TO pjpuebla;

--
-- Name: acuerdo_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: pjpuebla
--

CREATE SEQUENCE mediacion.acuerdo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.acuerdo_id_seq OWNER TO pjpuebla;

--
-- Name: acuerdo_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: pjpuebla
--

ALTER SEQUENCE mediacion.acuerdo_id_seq OWNED BY mediacion.acuerdo.id;


--
-- Name: asesoria; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.asesoria (
    id integer NOT NULL,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_creo character varying(50) NOT NULL,
    persona_atendida_id integer NOT NULL,
    materia_id integer NOT NULL
);


ALTER TABLE mediacion.asesoria OWNER TO pjpuebla;

--
-- Name: asesoria_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: pjpuebla
--

CREATE SEQUENCE mediacion.asesoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.asesoria_id_seq OWNER TO pjpuebla;

--
-- Name: asesoria_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: pjpuebla
--

ALTER SEQUENCE mediacion.asesoria_id_seq OWNED BY mediacion.asesoria.id;


--
-- Name: asistencia; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.asistencia (
    solicitud_id integer NOT NULL,
    sesion_mediacion_id integer NOT NULL,
    fecha_asistencia date DEFAULT CURRENT_DATE NOT NULL,
    asiste_usuario boolean DEFAULT true NOT NULL,
    asiste_invitado boolean DEFAULT true NOT NULL,
    tipo smallint DEFAULT 1 NOT NULL,
    acepta_usuario boolean DEFAULT true NOT NULL,
    acepta_invitado boolean DEFAULT true NOT NULL,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_creo character varying(50) NOT NULL,
    fecha_actualizacion timestamp without time zone,
    usuario_actualizo character varying(50),
    id integer NOT NULL
);


ALTER TABLE mediacion.asistencia OWNER TO pjpuebla;

--
-- Name: asistencia_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: pjpuebla
--

CREATE SEQUENCE mediacion.asistencia_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.asistencia_id_seq OWNER TO pjpuebla;

--
-- Name: asistencia_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: pjpuebla
--

ALTER SEQUENCE mediacion.asistencia_id_seq OWNED BY mediacion.asistencia.id;


--
-- Name: config_citas; Type: TABLE; Schema: mediacion; Owner: postgres
--

CREATE TABLE mediacion.config_citas (
    id smallint NOT NULL,
    clave character varying NOT NULL,
    descripcion character varying,
    valor character varying NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE mediacion.config_citas OWNER TO postgres;

--
-- Name: config_citas_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: postgres
--

CREATE SEQUENCE mediacion.config_citas_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.config_citas_id_seq OWNER TO postgres;

--
-- Name: config_citas_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: postgres
--

ALTER SEQUENCE mediacion.config_citas_id_seq OWNED BY mediacion.config_citas.id;


--
-- Name: det_config_citas; Type: TABLE; Schema: mediacion; Owner: postgres
--

CREATE TABLE mediacion.det_config_citas (
    id integer NOT NULL,
    clave character varying NOT NULL,
    descripcion character varying,
    valor character varying,
    activo boolean DEFAULT true NOT NULL,
    config_id integer NOT NULL,
    fecha_inicio timestamp without time zone NOT NULL,
    fecha_fin timestamp without time zone
);


ALTER TABLE mediacion.det_config_citas OWNER TO postgres;

--
-- Name: det_config_citas_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: postgres
--

CREATE SEQUENCE mediacion.det_config_citas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.det_config_citas_id_seq OWNER TO postgres;

--
-- Name: det_config_citas_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: postgres
--

ALTER SEQUENCE mediacion.det_config_citas_id_seq OWNED BY mediacion.det_config_citas.id;


--
-- Name: detalle_usuario_solicitud; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.detalle_usuario_solicitud (
    solicitud_id integer NOT NULL,
    tipo_identificacion_id integer NOT NULL,
    persona_id integer NOT NULL,
    numero_identificacion integer NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE mediacion.detalle_usuario_solicitud OWNER TO pjpuebla;

--
-- Name: expediente; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.expediente (
    id integer NOT NULL,
    folio character varying(100) NOT NULL,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    mediador_id integer NOT NULL,
    solicitud_id integer NOT NULL,
    es_mediable boolean DEFAULT true NOT NULL,
    hay_acuerdo boolean NOT NULL,
    asistencia_psicologica boolean DEFAULT false,
    asistencia_juridica boolean DEFAULT false,
    estatus smallint DEFAULT 1
);


ALTER TABLE mediacion.expediente OWNER TO pjpuebla;

--
-- Name: expediente_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: pjpuebla
--

CREATE SEQUENCE mediacion.expediente_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.expediente_id_seq OWNER TO pjpuebla;

--
-- Name: expediente_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: pjpuebla
--

ALTER SEQUENCE mediacion.expediente_id_seq OWNED BY mediacion.expediente.id;


--
-- Name: fase_mediacion; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.fase_mediacion (
    id integer NOT NULL,
    secuencia smallint NOT NULL,
    clave character varying(20) NOT NULL,
    descripcion character varying NOT NULL,
    activo boolean DEFAULT false NOT NULL
);


ALTER TABLE mediacion.fase_mediacion OWNER TO pjpuebla;

--
-- Name: fase_mediacion_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: pjpuebla
--

CREATE SEQUENCE mediacion.fase_mediacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.fase_mediacion_id_seq OWNER TO pjpuebla;

--
-- Name: fase_mediacion_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: pjpuebla
--

ALTER SEQUENCE mediacion.fase_mediacion_id_seq OWNED BY mediacion.fase_mediacion.id;


--
-- Name: formato_fase; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.formato_fase (
    fase_id integer NOT NULL,
    formato_id integer NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    opcional boolean DEFAULT false NOT NULL
);


ALTER TABLE mediacion.formato_fase OWNER TO pjpuebla;

--
-- Name: mediador; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.mediador (
    id integer NOT NULL,
    usuario_id integer NOT NULL,
    numero integer DEFAULT 9999 NOT NULL,
    certificado character varying,
    estatus smallint DEFAULT 1 NOT NULL,
    supervisado_por integer,
    fecha_registro timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_registro character varying(50) NOT NULL,
    "fecha_actualización" timestamp without time zone,
    usuario_actualizo character varying(50)
);


ALTER TABLE mediacion.mediador OWNER TO pjpuebla;

--
-- Name: mediador_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: pjpuebla
--

CREATE SEQUENCE mediacion.mediador_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.mediador_id_seq OWNER TO pjpuebla;

--
-- Name: mediador_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: pjpuebla
--

ALTER SEQUENCE mediacion.mediador_id_seq OWNED BY mediacion.mediador.id;


--
-- Name: solicitud; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.solicitud (
    id integer NOT NULL,
    folio character varying(100) NOT NULL,
    fecha_solicitud date DEFAULT CURRENT_DATE NOT NULL,
    usuario_persona_id integer NOT NULL,
    invitado_persona_id integer NOT NULL,
    fecha_sesion timestamp without time zone,
    es_mediable boolean DEFAULT true NOT NULL,
    canalizado boolean DEFAULT false NOT NULL,
    descripcion_conflicto text NOT NULL,
    materia_id integer NOT NULL,
    asesoria_id integer,
    tipo_apertura_id integer NOT NULL,
    tipo_cierre_id integer,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_creo character varying(50) NOT NULL,
    fecha_actualizacion timestamp without time zone,
    usuario_actualizo character varying(50),
    estatus smallint DEFAULT 0
);


ALTER TABLE mediacion.solicitud OWNER TO pjpuebla;

--
-- Name: tipo_apertura; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.tipo_apertura (
    id integer NOT NULL,
    clave character varying(10) NOT NULL,
    descripcion character varying NOT NULL,
    activo boolean DEFAULT true
);


ALTER TABLE mediacion.tipo_apertura OWNER TO pjpuebla;

--
-- Name: qry_solicitud; Type: VIEW; Schema: mediacion; Owner: postgres
--

CREATE VIEW mediacion.qry_solicitud AS
 SELECT s.id,
    s.folio,
    s.fecha_solicitud,
    m.descripcion AS materia,
    p.nombre AS usuario_nombre,
    p.apellido_paterno AS usuario_apaterno,
    p.apellido_materno AS usuario_amaterno,
    p.sexo AS usuario_sexo,
    p.persona_moral AS usuario_persona_moral,
    core.nombre_persona(p.id) AS usuario_nombre_completo,
        CASE
            WHEN (p.representante IS NULL) THEN ''::character varying
            ELSE core.nombre_persona(p.representante)
        END AS usuario_representante,
    ( SELECT persona.sexo
           FROM core.persona
          WHERE (persona.id = p.representante)) AS usuario_representante_sexo,
    p2.nombre AS invitado_nombre,
    p2.apellido_paterno AS invitado_apaterno,
    p2.apellido_materno AS invitado_amaterno,
    p2.sexo AS invitado_sexo,
    p2.persona_moral AS invitado_persona_moral,
    core.nombre_persona(p2.id) AS invitado_nombre_completo,
        CASE
            WHEN (p2.representante IS NULL) THEN ''::character varying
            ELSE core.nombre_persona(p2.representante)
        END AS invitado_representante,
    ( SELECT persona.sexo
           FROM core.persona
          WHERE (persona.id = p2.representante)) AS invitado_representante_sexo,
    s.descripcion_conflicto,
    s.fecha_sesion
   FROM ((((mediacion.solicitud s
     JOIN core.persona p ON ((p.id = s.usuario_persona_id)))
     JOIN core.persona p2 ON ((p2.id = s.invitado_persona_id)))
     JOIN core.materia m ON ((m.id = s.materia_id)))
     JOIN mediacion.tipo_apertura ta ON ((ta.id = s.tipo_apertura_id)));


ALTER TABLE mediacion.qry_solicitud OWNER TO postgres;

--
-- Name: revision_acuerdo; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.revision_acuerdo (
    acuerdo_id integer NOT NULL,
    usuario_id_revisor integer NOT NULL,
    fecha_asignacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fecha_revision timestamp without time zone NOT NULL,
    archivo_id integer NOT NULL,
    estatus smallint DEFAULT 0 NOT NULL,
    observaciones text
);


ALTER TABLE mediacion.revision_acuerdo OWNER TO pjpuebla;

--
-- Name: seq_foliador; Type: SEQUENCE; Schema: mediacion; Owner: postgres
--

CREATE SEQUENCE mediacion.seq_foliador
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.seq_foliador OWNER TO postgres;

--
-- Name: sesion_mediacion; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.sesion_mediacion (
    id integer NOT NULL,
    expediente_id integer NOT NULL,
    numero smallint DEFAULT 1,
    fecha_sesion timestamp without time zone NOT NULL,
    observaciones text,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_creo character varying(50) NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    usuario_actualizo integer
);


ALTER TABLE mediacion.sesion_mediacion OWNER TO pjpuebla;

--
-- Name: sesion_mediacion_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: pjpuebla
--

CREATE SEQUENCE mediacion.sesion_mediacion_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.sesion_mediacion_id_seq OWNER TO pjpuebla;

--
-- Name: sesion_mediacion_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: pjpuebla
--

ALTER SEQUENCE mediacion.sesion_mediacion_id_seq OWNED BY mediacion.sesion_mediacion.id;


--
-- Name: solicitud_archivo; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.solicitud_archivo (
    solicitud_id integer NOT NULL,
    formato_id integer NOT NULL,
    archivo_id integer,
    estatus integer DEFAULT 1,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_creo character varying(50) NOT NULL,
    fecha_actualizacion timestamp without time zone,
    usuario_actualizo character varying(50),
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    persona_firma character varying
);


ALTER TABLE mediacion.solicitud_archivo OWNER TO pjpuebla;

--
-- Name: solicitud_electonica; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.solicitud_electonica (
    solicitud_id integer NOT NULL,
    url character varying NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    num_sesion smallint NOT NULL
);


ALTER TABLE mediacion.solicitud_electonica OWNER TO pjpuebla;

--
-- Name: solicitud_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: pjpuebla
--

CREATE SEQUENCE mediacion.solicitud_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.solicitud_id_seq OWNER TO pjpuebla;

--
-- Name: solicitud_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: pjpuebla
--

ALTER SEQUENCE mediacion.solicitud_id_seq OWNED BY mediacion.solicitud.id;


--
-- Name: solicitud_juzgado; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.solicitud_juzgado (
    solicitud_id integer NOT NULL,
    juzgado_id integer NOT NULL,
    persona_id_turno integer,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE mediacion.solicitud_juzgado OWNER TO pjpuebla;

--
-- Name: tipo_apertura_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: pjpuebla
--

CREATE SEQUENCE mediacion.tipo_apertura_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.tipo_apertura_id_seq OWNER TO pjpuebla;

--
-- Name: tipo_apertura_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: pjpuebla
--

ALTER SEQUENCE mediacion.tipo_apertura_id_seq OWNED BY mediacion.tipo_apertura.id;


--
-- Name: tipo_cierre; Type: TABLE; Schema: mediacion; Owner: pjpuebla
--

CREATE TABLE mediacion.tipo_cierre (
    id integer NOT NULL,
    clave character varying(10) NOT NULL,
    descripcion character varying NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE mediacion.tipo_cierre OWNER TO pjpuebla;

--
-- Name: tipo_cierre_id_seq; Type: SEQUENCE; Schema: mediacion; Owner: pjpuebla
--

CREATE SEQUENCE mediacion.tipo_cierre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE mediacion.tipo_cierre_id_seq OWNER TO pjpuebla;

--
-- Name: tipo_cierre_id_seq; Type: SEQUENCE OWNED BY; Schema: mediacion; Owner: pjpuebla
--

ALTER SEQUENCE mediacion.tipo_cierre_id_seq OWNED BY mediacion.tipo_cierre.id;


--
-- Name: archivo id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.archivo ALTER COLUMN id SET DEFAULT nextval('core.archivo_id_seq'::regclass);


--
-- Name: area id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.area ALTER COLUMN id SET DEFAULT nextval('core.area_id_seq'::regclass);


--
-- Name: clasificacion_persona id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.clasificacion_persona ALTER COLUMN id SET DEFAULT nextval('core.clasificacion_persona_id_seq'::regclass);


--
-- Name: estado id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.estado ALTER COLUMN id SET DEFAULT nextval('core.estado_id_seq'::regclass);


--
-- Name: formato id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.formato ALTER COLUMN id SET DEFAULT nextval('core.formato_id_seq'::regclass);


--
-- Name: instituciones id; Type: DEFAULT; Schema: core; Owner: postgres
--

ALTER TABLE ONLY core.instituciones ALTER COLUMN id SET DEFAULT nextval('core.instituciones_id_seq'::regclass);


--
-- Name: juzgado id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.juzgado ALTER COLUMN id SET DEFAULT nextval('core.juzgado_id_seq'::regclass);


--
-- Name: materia id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.materia ALTER COLUMN id SET DEFAULT nextval('core.materia_id_seq'::regclass);


--
-- Name: modulo id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.modulo ALTER COLUMN id SET DEFAULT nextval('core.modulo_id_seq'::regclass);


--
-- Name: municipio id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.municipio ALTER COLUMN id SET DEFAULT nextval('core.municipio_id_seq'::regclass);


--
-- Name: permiso id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.permiso ALTER COLUMN id SET DEFAULT nextval('core.permiso_id_seq'::regclass);


--
-- Name: persona id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.persona ALTER COLUMN id SET DEFAULT nextval('core.persona_id_seq'::regclass);


--
-- Name: rol id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.rol ALTER COLUMN id SET DEFAULT nextval('core.rol_id_seq'::regclass);


--
-- Name: sede id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.sede ALTER COLUMN id SET DEFAULT nextval('core.sede_id_seq'::regclass);


--
-- Name: tipo_identificacion id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.tipo_identificacion ALTER COLUMN id SET DEFAULT nextval('core.tipo_identificacion_id_seq'::regclass);


--
-- Name: tipo_juzgado id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.tipo_juzgado ALTER COLUMN id SET DEFAULT nextval('core.tipo_juzgado_id_seq'::regclass);


--
-- Name: usuario id; Type: DEFAULT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.usuario ALTER COLUMN id SET DEFAULT nextval('core.usuario_id_seq'::regclass);


--
-- Name: acuerdo id; Type: DEFAULT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.acuerdo ALTER COLUMN id SET DEFAULT nextval('mediacion.acuerdo_id_seq'::regclass);


--
-- Name: asesoria id; Type: DEFAULT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.asesoria ALTER COLUMN id SET DEFAULT nextval('mediacion.asesoria_id_seq'::regclass);


--
-- Name: asistencia id; Type: DEFAULT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.asistencia ALTER COLUMN id SET DEFAULT nextval('mediacion.asistencia_id_seq'::regclass);


--
-- Name: config_citas id; Type: DEFAULT; Schema: mediacion; Owner: postgres
--

ALTER TABLE ONLY mediacion.config_citas ALTER COLUMN id SET DEFAULT nextval('mediacion.config_citas_id_seq'::regclass);


--
-- Name: det_config_citas id; Type: DEFAULT; Schema: mediacion; Owner: postgres
--

ALTER TABLE ONLY mediacion.det_config_citas ALTER COLUMN id SET DEFAULT nextval('mediacion.det_config_citas_id_seq'::regclass);


--
-- Name: expediente id; Type: DEFAULT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.expediente ALTER COLUMN id SET DEFAULT nextval('mediacion.expediente_id_seq'::regclass);


--
-- Name: fase_mediacion id; Type: DEFAULT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.fase_mediacion ALTER COLUMN id SET DEFAULT nextval('mediacion.fase_mediacion_id_seq'::regclass);


--
-- Name: mediador id; Type: DEFAULT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.mediador ALTER COLUMN id SET DEFAULT nextval('mediacion.mediador_id_seq'::regclass);


--
-- Name: sesion_mediacion id; Type: DEFAULT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.sesion_mediacion ALTER COLUMN id SET DEFAULT nextval('mediacion.sesion_mediacion_id_seq'::regclass);


--
-- Name: solicitud id; Type: DEFAULT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud ALTER COLUMN id SET DEFAULT nextval('mediacion.solicitud_id_seq'::regclass);


--
-- Name: tipo_apertura id; Type: DEFAULT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.tipo_apertura ALTER COLUMN id SET DEFAULT nextval('mediacion.tipo_apertura_id_seq'::regclass);


--
-- Name: tipo_cierre id; Type: DEFAULT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.tipo_cierre ALTER COLUMN id SET DEFAULT nextval('mediacion.tipo_cierre_id_seq'::regclass);


--
-- Data for Name: archivo; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.archivo (id, nombre, tipo, data, fecha_creacion, usuario_creo) FROM stdin;
2	Solicitud01010.pdf	application/pdf	\\x255044462d312e370d0a25b5b5b5b50d0a312030206f626a0d0a3c3c2f547970652f436174616c6f672f50616765732032203020522f4c616e6728657329202f53747275637454726565526f6f74203130203020522f4d61726b496e666f3c3c2f4d61726b656420747275653e3e2f4d65746164617461203230203020522f566965776572507265666572656e636573203231203020523e3e0d0a656e646f626a0d0a322030206f626a0d0a3c3c2f547970652f50616765732f436f756e7420312f4b6964735b2033203020525d203e3e0d0a656e646f626a0d0a332030206f626a0d0a3c3c2f547970652f506167652f506172656e742032203020522f5265736f75726365733c3c2f466f6e743c3c2f46312035203020523e3e2f4578744753746174653c3c2f4753372037203020522f4753382038203020523e3e2f50726f635365745b2f5044462f546578742f496d616765422f496d616765432f496d616765495d203e3e2f4d65646961426f785b2030203020363132203739325d202f436f6e74656e74732034203020522f47726f75703c3c2f547970652f47726f75702f532f5472616e73706172656e63792f43532f4465766963655247423e3e2f546162732f532f537472756374506172656e747320303e3e0d0a656e646f626a0d0a342030206f626a0d0a3c3c2f46696c7465722f466c6174654465636f64652f4c656e677468203138313e3e0d0a73747265616d0d0a789cadcf4b0b82401405e0fdc0fc87b3d4a079a1a38208f9a448b0340aa2850b739554fe7f68921611b489eee2c285c3f9b8e0f5b51d1086bc4c9629045fb7430fab1be7e5c18e22c469821b258289e7045241409bed050af78e92fd0c0325714309cf253c85e64c8934210109df655238d0ae625aa3b99850517be84753887ebafcd7555072b4609fd0ac28c94cdd86929f5da90473dfd9497b21d57697c50b5469fe27cd097ce67dd33e5e4256267800e2e8488b0d0a656e6473747265616d0d0a656e646f626a0d0a352030206f626a0d0a3c3c2f547970652f466f6e742f537562747970652f54727565547970652f4e616d652f46312f42617365466f6e742f4243444545452b43616c696272692d426f6c642f456e636f64696e672f57696e416e7369456e636f64696e672f466f6e7444657363726970746f722036203020522f4669727374436861722033322f4c617374436861722038352f576964746873203138203020523e3e0d0a656e646f626a0d0a362030206f626a0d0a3c3c2f547970652f466f6e7444657363726970746f722f466f6e744e616d652f4243444545452b43616c696272692d426f6c642f466c6167732033322f4974616c6963416e676c6520302f417363656e74203735302f44657363656e74202d3235302f436170486569676874203735302f4176675769647468203533362f4d6178576964746820313738312f466f6e74576569676874203730302f58486569676874203235302f5374656d562035332f466f6e7442426f785b202d353139202d3235302031323633203735305d202f466f6e7446696c6532203139203020523e3e0d0a656e646f626a0d0a372030206f626a0d0a3c3c2f547970652f4578744753746174652f424d2f4e6f726d616c2f636120313e3e0d0a656e646f626a0d0a382030206f626a0d0a3c3c2f547970652f4578744753746174652f424d2f4e6f726d616c2f434120313e3e0d0a656e646f626a0d0a392030206f626a0d0a3c3c2f417574686f7228706a336738367a7733406f75746c6f6f6b2e636f6d29202f43726561746f7228feff004d006900630072006f0073006f0066007400ae00200057006f007200640020003200300032003129202f4372656174696f6e4461746528443a32303234303132323131353130352d30362730302729202f4d6f644461746528443a32303234303132323131353130352d30362730302729202f50726f647563657228feff004d006900630072006f0073006f0066007400ae00200057006f007200640020003200300032003129203e3e0d0a656e646f626a0d0a31372030206f626a0d0a3c3c2f547970652f4f626a53746d2f4e20372f46697273742034362f46696c7465722f466c6174654465636f64652f4c656e677468203331343e3e0d0a73747265616d0d0a789c6d515d8bc230107c17fc0ffb0fb6396b511041fcc0432ca515ee417c8875af0db689c414f4df5ff6dac31ef8126626b3b3bb891843002284b100e1413006e1d13402f10161e495118493118808c2e90466334cd81d408a19267878de0833679bdcad2baa717784e00498143062cf7c3e1cb4254157b23279539376ef2a058f929ea0abea390e962835c6616a2adacb1bcfc87989b43e8b6f795c5638266c637ab7313ddc8e9e20bae88dcfd2c611c67cacf5e5450ede7a360fcc2877b8257921db62aef9c39fba529ab252f2842c2cb44f904e19dd71ebd4b7f4e0977d197b3d1b737d6dcfcabd24723ca4c3bdccade9f165e9cf1e5f295999a2276495ba50cfdbf6f1b6c2ca1a37aa68ac5f45b98a702b70696aeebad07969fc0637a9bb77889bfa7ee4ff8ffebd7c2c6bba1f5bfafa96e1e0078b10acbe0d0a656e6473747265616d0d0a656e646f626a0d0a31382030206f626a0d0a5b2032323620302030203020302030203020302030203020302030203020302030203020302030203020302030203020302030203020302030203020302030203020302030203630362035363120302036333020343838203435392030203020302030203020302030203020302035333220302035363320302030203635335d200d0a656e646f626a0d0a31392030206f626a0d0a3c3c2f46696c7465722f466c6174654465636f64652f4c656e6774682032323534382f4c656e677468312038353337323e3e0d0a73747265616d0d0a789cec9d097c5445d6e84fdddbfb9274674f3abd249deeec9d95900548139210085b20ad09b22424c1b820211010054154d008a2e2328a0b6ea323209d660b828a888ea3a2ce88fba88c32e31a45471d45d3fd4eddd30901b71987f7f9bedfeb939cfe579d5a6ed53975ebd60dd1000300037ec8a0a9aaa2b2feba47ce6e02965c8f067f55c584319b7e37df0cccda0a201c9b3c2d27ffcecfda3e07605762aba69679cd1d8bd77d7e36c0f995583faa65f1225bf9c30d9f005c3b034071e5dc8eb3e7ddf551c516808e060075e4d9e72f9dbb6ddeb9af03dc7414c0f64c7b5b736b40bbf501ec4f87fd15b5a341bf37f125cc637f90d23e6fd1850f2a22afc0fc0700e7ce387f7e4bb3fd0ad31d00bbbd00c315f39a2fec4857c71ec6f276ac6f9bd7b6a8f9d6559b16034bc5f1c3e51734cf6b2b5cb32e0ae0d35e80dcb51df3172e0a986035ce87f76febe86ceb284e5c771060e9f900317dc07da1a858dff6e6845db3c3477c05f12ae0b2f7e365cf71bef5cd3dcf7cf746ff304d826a0ad655830024d84e017e6007359bbe7be3f86a4d82d4d31089dfc22da655b0120c300c446c69801c6802d00bd2751988b2f1c23e90834a7e8bbc00bbb410c517e161015420842b0551261305d95170050e40cac5d8ad9af73d719acd063600c7733406e51d82d3062cc0cbc4fdf2303e538892859d180d7b01a3f53ac4c27f28b265b0eea7cae4da93cbc4f77fbaee49f5b6fc7bf54eb728fca7efbab28a137dc92efd75fdca4b60ede91acf2f896c2c68fee336c578dffc54d975279789eb7fbaee49f51afebd7aa75b1435a7efba62ff89be648e5fd7af6c0b5c7ebac6f35b8bac166a7feb3184e4bf17e135b8e4b71ec3ff0611be82d25fd50e60fae91e4b484212929084e4d78bb011fef19365e7c00bff9363f9df22e22a58fa5b8f21242109494842f2eb45f638ccfd6ffb1023214ed4c08552fa3cb850d88d7a3de57ff49ab79e2813be0cb6d39fb08917c205ffed98421292908424242109494842129290842424ff3b85bf634a3ce53df3e7da0c7dcf1c10febe39f0ae197acf0c494842129290842424210949484212929084242421f96d85ddf25b8f20242109494842129290842424210949484212929084242421094948421292908424242109494842129290842424210949484212929084242421094948421292908424242481877feb1184242421f98f44862aa2a604fff2d5279863525ee47f6b48780d6b3c8df90cb0618afff5213d24430554c344980253c103add0099bcc59669739cf5c622e378fb6a91dcf05a4bf6285756d301a2a7fa46e2ed61d35589705bea2e104fe054a504124ec620981968fd79cf8ea4b7d6764708c4e1c4dd62fce4c14c78b37e3988d100789d846c13e91ec9f9ffa37be302f04ff2298003f2f6c48cfff8df05141705c43a552fa3c1306fec648fbcf0e26e167cafec7fe26d56912f1b4f6c6ff2a1db0118f5c2abb0f13f1434a7804f541e5d1b605955f3f89541c8f4c2695e23c3aa8fc5ea9082a8f5f6550f9ffd3aa2aa889a8d541e5b19d18545e6f4a50797ca70695c7d913541eed565229b69da4522c370515c769ce22556d47ba48553b91b9a87998de8d2c2155ed478e422dc7f493c8d1a42abca76d6a527d2eff1b74a472b5bb7af6ac9933ce9aded8e0a99f36b56ecae4491327d48e1f5733b6baaa724cc56877f9a89123ca4a4b8a87170dcb716567a5391d29f6646b5c94d110aed76ad42aa5422e1305065955f6ea269bd7d9e49539ed3535d93c6f6f4643f3104393d786a6ea93eb786d4d5235dbc935dd5873ee2935dd54d33d5893196c2360447696adca6ef31eaab4db7ad9f4ba064cafabb437dabc7d527aa2949639a58c1e334949d8c25615d75e69f3b2265b95b77a717b77555325f6d7a3d58cb18f69d36467418f468b492da6bc69f68e1e96368a490921adaab44700959e5fd62b3aaa9a5bbd53ea1aaa2a4d49498d920dc6487d791563bc4aa92fdb397ccc70b5ad276b7ff7da5e03cc69cad4b5da5b9b673478c5666cd42d567577aff11a33bde9f64a6ffa4547e370ca6dde2c7b659537d38e9dd54e1dbc00f3ca1d06bbadfb2bc0c1dbfb3e39d9d21cb4281c86af8027f91407dd84e50369c0b1e108717e49497c2c57f7ba610e66bc2beb1a286f8339261fb873321bbd42132fd93f5012ede1252b074a069b37d99378a8aa9a82df8bdbe3bc2be7d8b2b3d0fbd2b703bfb1dce6159d4d735ada399bdbbaed9595e4b7fa06afbb1213eee6e05cab7a7273b07e73134ee21cee86ba066f8ebdc31b65afa00a68b0f1189c33ad416a126ce68d1ae385a696602b6f4e55251f97adaabba99206c8fbb2d735ec8182c0919e429b697b011442231f8737660c06c559d5ddd03ad76b6d32b5e2fa9c6b6b302579dd8de8be467b435b238f92dde04d3f82974b92ae28b5c2b99d527ba0329fb9d2a1b2350826b191470b0db66afcb0578cc00203864bcaf288568cb03530130c54c3ab046bf0d449fd6046748ca9e145226f3aa6c694d49844f233433205c72477785543fa32a061704c749d9f1c1ad5e6034ab755b5550e19e0499dca83030cf6f6e3e314b82f8217c6162a1ece9a8122d181772eda04ec4632f128c6d9bc30c5d6606fb337da710db9a734f0b9715f4bf1ad9d66afad9bde20453bb84aea4fca517931e5bc9084c50319610caec1ea4cd34058a5fc58293f98ad39a578dc40b1ad5b65af9dd6cd3bb7073b041bde41386985735cf3d5c51185786b56e3ee66af6eb6db0cb6eaeee6dec0ca39dd3d6e77774755537b29efc33eaeb5db3ead6184491aebd486e5a68bf8a522a096d5d6576467e1de53d1636757d6f5b8d995d3a637ec31e0be7e657d834f60c298a68ac69e142c6bd8834f39b76415b8951b79c6c633bca7a9985149f54d7bdc002ba552996490f22dbd0c249b6ac0c6a0a557209b61c026a04d4636b764e382418a6b4717e3765b656be5e159d6d8deddd4c86f2e88c150e237f332fb28f00af6513d4c50e8bc1a7b5b85576bafe0f6726e2f27bb82db95b830580c43e7f03da9bbc98efb142ea80630315a8a22efd2d61b08d437241d32f53526e1529b813abdc1abcec4bd5fee188ff5c6726d42f358efca96663e0ef034f0b64ac7b896465cb6031d6295715e35f6a00ef68035aaa5367c3962a3168c0d06506abf1233de958ddec64c7ed186731aa5e56cf0428dbd14c34e7dca9dfc42398ddd11f67ce9dec45b41e358c3a1c6b1c1b406b298308b176b2427297538f2163b16b534d9d0db326899864b9df6528d892c6db825ca9c6d926a4cc142e0d3121d5abdc6ab766187f8cdd35a17bf25e50e6563230d5ecaad0956c06b1bbc5a1c9173882b830dd03b58348e8f05bfd7e05079d5c7793775bd30d57e21ee2c7cd0524f4a2cf6ea1de39a71f3a7f65ab4d88b071aabf81ea10df67190ac4a3e731dfa5d74d4f706eeb72f4d1a22d95976fe70e00b134c7b70614363f7a906ef5999d959aa53ad7ac9dcddadd2ff7803f2974a3f4834824f2d7e3cda2c8ec1255f268ec6cfabc55cd8882a804ccc8156d445a887516562b69801c56015b382cc14337cc5d694c7307b2fea0e5431b01f8df6d4ea3d5222d1563dba451c01c5621978c4526409b218391c59841c862c441620edc8646412d286e7c64c91df8ae7f14f71249561ae0c6d29621ed4a30a52aa3098fb12550651622a54a21e451571d4a958872c8b502f47bd01f530ea97a82a1c7a32f658885764d8d686b56d58db863ddab0850d5bd840217cebb398adbdc2373e4b26e25f3e4b16e26bc257842fa9ec9f94fb82f039e118e133c2a754b38ff009193f267c44f890f001e17dc23f087f271cf559d488f728f72ee16f3e7304e288cf1c8f78c767ce41bc4d788bf057c29b54e50dcabd4e788df02ae115c2cb84c38497087f21fc99f022e105c2f334884384e708cf129ea1cbfe896a3e4df823e129c293848384270807088f13f6131ea33e1f253c42c67d84bd8487097b08bd84dd845d849d841d84ed041fa1c797988ff012b6f9120b100f11b612b61036131ef425e621fe407880dadd4ff83de13ec2bd847b087753f3bb089b087712ee20dc4eb88dbade48b8959adf42f81de166c24d841ba9dd0d840d84eb09d711ae25ac275c435dafa3e66b095713ba095711aea4066b08ab0957102e275c4658e53315222e25ac24ac205c42584e5846b89870116129e142c212c262421761116121a193b080d04198ef4b1886b880308f703ee13cc2b9847308ed84b30973096d8456420b610ea199d044984d984598499841388b309dd0e88b1f8e68209c493883e021d413a611a612ea0853089309930813091308b584f18471841ac2584235a18a50491843a8208c26b809e584518491841184324229a1c417578228260c27141186110a0905847c421e215782c87c712ecce590d145c82664113209198474421a2195e024387cb165881482dd17cb1774b22fb6149144461bc14ab010cc8444828990408827c4116209318468ba42145d21928c110423c14008278411f4041d414bd010d4d4a78aa024a3822027c8082241203002486001829fd04ff89ef01de138e15bc237847f4997655f4b33625f91f14bc23f095f103e271c237c46f894d047f884f031e123c287840f08efd3f5fee18bb123fe4e38ea8bc105c6de23bceb8b2946fc8d70c4173306f18e2fa612f136e12dc25f7d315588377d31d5883708af135ea3ae5f25bc429dbd4c9d1d26bc44f80b75f6676af722e105c2f3844384e708cf52bb67a8eb3f119ea6c1ff91f0145def495f4c05e2203578822e748046fd3875b69ff018e151c223847d84bd8487a9eb3dd4752f75bd9bbade45d849d84117da4ef0117ae8b25ec236c243d4f556c216c266c283843ff8a271df650ff8a24723ee27fcde173d11719f2f7a12e25e5ff464c43dbee8a988bb7dd16ec45d54651355b993aadc41556ea7b2dba8e646cadd4a356f21fc8e1adc4cb8c9173d05712335bf81b081703d0de93aaa792dd55c4fb8c6175d87584735d712ae2674fba21a1057f9a21a1157faa26620d6f8a2662256fba2c623aef0459d85b89cca2ea39aaba8caa5ee6dc863e155d6cfc26aac477493ac07501f47dd8ffa98f60cab0fb507d58bba0df521d4ada85b5037a33e88fa07d40750ef47fd3dea7da8f7a2de837a37ea5da89b50ef44bd43d36ebd15f516d4dfa1de8c7a13ea8da837a06e40bd1ef53ad46bd5edd6f5a8d7a0ae435d8b3a5a2d7c2f1c8733c02a7c876c072b5be18be4b7e325be08beb4161116fa8c7c69751216103a08f3091710e611ce279c473897308250e6337094124a08c584e18422c2304221a18090ef0be7eb348f904b88201809064238218ca0f761507a998ea02568086a828aa0f4e979a815eeb3909fa2f6a17e82fa31ea47a81f6238df417d1bf52dd4bfa2be89fa06eaeb1896d7505f457d14f511d47da87b511f46bd1d43711b6a2f5b499ebec867e44b7e2939e742c212c2624217610ca182fc309ae0269413461146d294a3095184488e3da2280a3eb7f5de4745015fee0438882a8a4063b998308da23e954656479842984c984498489840a8258c278c23d410c612aa0955844a42322189066f235809168299904830111208f184389a662c21c6bd11d98ffa3dea77a8c751bfc5007f83fa2fd4af51bf42fd12f59f18d52f503f477d1ff51fa87f473d8afa1eeabba87fc3e81e427d0ef559d46750ff84fa34ea1f519f427d12f520ea13a8bda8bb31e2bb5077a2ee40dd8eba91475fe8271f2f272c239ce333e25188b513ce26b7cc25b4115a092d8439846642136136611661266106e12cc2744223a1817026e10c8287504fc821b8c8d5d9842c42262183904e4823a4129c0407c526856027c80932824810088cee4870df8d0ca0fa513f40c7be82fa32ea61d49750ff82fa67d417515f407d1e1dbd07f50ad161bd5c74592f632eebaa9a959e4b37aff4aca859eeb964f3728f7679d9f2dae5a276b90971f1f2cdcbdf5cae58567391e7e2cd17796417455d246896d62cf15cb8798947bb84e916d77479eabb8e767dd9254675d577b5762deabaa1eb301a94f776ede83ad825f606f6bb23ba8acbaa57765ddb254461b9005d2c9c9b93bab461d58b6a3a3d0b37777a649d859d42d9979dec482713723bd994cea64e016b6def4c49abe6b58775c624541b3a733bdd9de2829af99e8ecdf33d93e7cf9fbf62fe9df31f9b2f5f317ffd7c611ba604f77cb5befa829a799e77e631d82704c080ba5f08f844cdfcbd821f187c26f8dd01761e3ae05c74c439aeb33ded9bcff6cc75b57ada36b77aacade5ad428b6b8ea7d9d5e499ed9ae999b579a667866bbae7accdd33dd6e9e5d385465783e74c6c7986abdee3d95cef99e6aaf34cdd5ce799ec9ae49984f689ae5acf84cdb59ef1ae1acfb8cd359e29356cacabda53251659f1590216fceeb0acb41cb3c8b44de60eb3d0613e623e66163b128f250a2b4c2c3c6145c2fa04311c3f04fa88b7c6af8fbf337e5bbc3c5c4a88ba8e889511428771a551c835ba8d2f1a8f186560dc6414c2d787df19be2d5c9c1c3e3bfcb3f040b86c5b38db16f658d80b61e2e4b0d961f3c3c4f0309e17dd750677982baf3a5c6fd5e7e8c51139fa72fd64bdb85ecfdc7a577eb55b9f925a5dae9bac9bad13efd431b7ce995efd9926a011dc1a2cf84c1d500b01350391d918036640882a8cd20e166dad161f61fc9f68e5c0d8b5509f59dbab0c4cadf5aaa69ce565577a1dd3f8a7bb6eba5771a5173cd3cf6ae861ec9ac61e268ca9f746f19fb24bf92bd6ad037345add73cadc1276eda64ae68acf5aee469b75b4a07781ab04a63e6ac855d0b172eca5c98891fa8b316a26551177e4b60f889ec5ac44b162d04ac923944169e0cacb390a34b322dec9add85bd60019a174a669e9b2555c9fc7f4116fe7295ff7bc27ecb8bffff2d804b99afeb854317225f0cb84e17c6cd9e25fd9a84f20e00ff8621bf3771297edd069b61273c0c8fc333f012fc9369a009ae80c7e03df808be80eff0ce55b26896c8d27fe1b733fe03f15f269f077a713f28201620703cf0a1ff0f810f7183081b62d980b95899f384251011e83bd5e6dfe0eff53fafd082416a6b109e45eb31d617382e94f37ca088e785353c2db538a6bcc3bfcd7fe749c3e9804ee8820b61295c0417c372b80456c065b01ad6c0957015fa6205a6af86b5b00eae81f5702d5c07d7c306b8016e849be066f81ddc02b7c246f4e3ed7007dc192ce3f93bf0eb26a99497dc0dbf873fc016e43d702fdc07f7c303987f10bdbf051e421b5928bf152d9be02eb4fe1eadbc16b76dc32f2ff4800fb6c30e8c19e50772bdb01f76c16ee41e8ce65ed8078fc0a318c7fd18d903928d5b06f23f5d933e9f8083f0243c057f84a7e14fb8329e85e7e0103c0f2ffcaa9227072d3cf722fc19fe826bed30bc0cafc0abf03abc096fc33b7004dec555f7c90fca5fc31a6f609db782b5fe86b5fe0e1f62cd3eac49f5a8ce5fa5d20fa41e0e63db237094a9e02b26c07710c0148fde4d52846e91e2c8a3c7a373afe4671e8f6d98e711ba7f30365bd1c75b319e3cc7d3b706a3f110d6ed410f0ef8efc7bdf67c303ae4ef7d5887fb82971c0afae28fc148f07e1e1d6cfbac54e693da1d18ecf5844769862f0ff1ce5f87f8f0eff00fc933e43d2a3de13d5ee328d6e15ee67d9cecdb77b12d799fb7e5f6a16d78d91b98ff1077874fd0d39c1f4b91f818de1f4cbf1f2cef834fe133f84afa3c069fe37ef24ff812f35fa3e518e67e683dd5f22ffcfa06be85e318c1efa17f48aeff94927ef0638cf188c1042682ff44ea84555219933305ee692aa6661aa6637a16c6c2f1c0a23ca5443b5862fc4189ee47cad492258245b228dc2f63591c4b6026dc37cdccc2ac2c89250f298b1f2cb161899da53047b02c466a193fd8d68a356287d44d67b96c097e663217cbc1741e2b64c3d8705682966ccce763be14cb722556c0149803e7c371f907c273d87f14ee2a3dbf76d7963f08d1b029f04da0c27f77ff3e7117ab67cfa147c2208091ba80b961937c169c27ef087ccd92039fcbc7063e911d0f7cc2f2025f8246dc24cec5fbe06fb209b00ccf81e05f28be893bb6084a2881893009eaf7819edd8edb7a297b764765a52a5bf9286605b0b1674185e1bbdd1d2913f42653b97d9862ad58671c57ae5c2bd44379ffdb6f3d851f87224a720eb19cb7fa5ee933f43f652cc9e93bdc979bc78c494649a3c204a552a1b027bb8461a9cea28282fc51c2b042a73d394c906c8545c3478905f916418c1ab08c12789e896f7e3f59acea4f119626954dcb93b34c47ac3552a512ad16bda3c0165e3bd15e94962097a914a25ca54c2daab07b968c4f7e5e13979a684e8dd320cd89c8fe03f2b0e35fc8c3be3b5356f9dd3ee183928651298aa57aad2057ab6e4fb344a7e4258eacd587ebe561a6d88444a5ca18a6c9a869eebf25c111abd1c43a12121dbc2f477f197a2436705cf6843c0a92c1096ff153b2a7610fa4043ed8a10d6713ecbd810fdc669e72e8f4f6383dc4b0b018a756634fd680ccce8c76a703df40dd16b716742c42d4e952cd2976bb45a38f017b729c32c23c35c223f7405c797979446c49b1b1c0888e9d3d6b6641425f3e8bcf993533ee507ec1f235070fb2b883b3665232370fcfd0a693c7b09327fe8b6be5e66566363a62622866a96292324cb4273b9d45c319052a56691793643d3a454c715e418945273bd39f3055a6370fcb74154629746cbdc2601f5550569d6a541c60bbd9fc392919d172516dd033597f58a456a688cdb0cb9619a3b5a2a88d897caaff0d5c8beb006445b82a2d9009c570fb806fadc2869d09dae8682df07f7fcc7216f07f91d326a4e24bf8f6bc3c654a6f70de29f8e2ee561bea0ae378ae90bfe2bb95f538bf84beccf2be4c9c5c5f09cbe9cbcfe9c3f5195182ebd3d4f3eb7ac9cd6bc4252db327253b87190b8b0a92d021d17c8d5b4456e812ec76235fe0912792b222e798991d2b26f91f48cace4e62554bee5b3022ce352673f8ccaa34ff96b8dc7123afd85052991d33c6523abde6b64787d70eb7b2cbab3ace189516999a256bcf4a4dab5b569f33adb2d0a0c99f7c2e7b2775547a8cdf6bca29efff367b6c6e82ffdad8ec31fc376fb907f7a30723c00af3c97f8f41a4b011778f04e17a50435c709671bdcce55687d599a4599af8cf4fdcf213b36474ffe2a2fa371b904784933c221f32fffd331ffa768bff5969f613b67e7edf19fe6399b36f5c7ac555e7dfd09227dceaebdf544b13adbbf3a37b66dcb168f4f7d7162f78005f5a7146e25a9c51163c44f3e12113ae7787ab236d91369c51429c1e0794f0309e8f9d810f76e9d944a753113f10cd7869d8faba5469d8a9fc27436ec549d1cce4b3c5e550929363e0ebdeb4eb34f488ee709cea8e68c9603c258993d384abfb1773cf08abd5611ab95c13a6f6e7b335ea709e0e57fb97b2bff0f4d9b8a169c9499af8540b6e6b5aff416d2c6e74ce588d7f83362e95ff1ef6bac071b105fd950abb83fe5246f60a37b863f466b0989569e16ca2324ea7671394062d261f66674264e0d82e4c4746c62b7a0347b6630d8534d9303641d1cbcedae14eae8b97b6099c61707e99dc67078d2592c3dcc6d3d7ede03a1aeaa78167c2802771825af451235ba70ed3caa5f4429d353fd55960d1a3179bb95576b7253d4ee7bf57139766b1a42568fd16ad41ab50e087ecc6ac546d7c06f94ab1007d35025e255fb9b5fadcdcd89c1c8d2b2e2ea15768dd9192a7d36930b11b528aeae275dab8bd2c1bdce00a1cdb61b00b13f27a03c7dc369e8a35f04f3d7dc6e6e4e6b914d6b43aab677087e55b2c7f25c4bd353fbf9ce51ceecb371618f887b164644e4181b1003db9f3b45e6460114aaeb333be81e356ceec27f953dacb5901dfd579325ab1406bce75a4e426ea04ff55b2086b6e7272ae3542f4df24682d3968376b8bb2b7b82a726d3a162763c97a6b7ab1a3c7941aaf4fd118340a057ec8ccdf1dd51b35a29cfb3af1bbf706ed97161485db4b32beef175946694a7818b692f62c7c9e8a18854448874b826b3645b157d80046300b8fbbd5607448f71a3ecd32b72b143a7befe0838e65ee7047d7e9069611df9c33b96f8377f27fd46e60e9d94f5d6fb2a11b9958b9ea9195e7eb2dd26ad3e5a5b13cd7b4454beab3fc7db9d513d33b16977b8a12c52be63db07084bf6570e66b737294b1a366af9853d990a1f58f4b1ee909ce7b22cebb082a6123cd7b87c1654cd7ec159ec2fd7ab8b0d1975e6e947e67c6651818ba019f4edbddeed891038691f880dae54eaa8b1d580303d3911e7587711bc7a77a097fd4fdaa4e86aca154d125fec03931b11631f8e48b8d8d896185ce54a773c057135596d2fc8c7cb34eb6283a2dcf9d3175c06df810985c50619ab4fc4c57927bd6087341765ae4bc708d7f6b69455441f6e2d5c5f5c589c9da708d4ca635ea5852de8482047fe4a0376fce4a9589daa233974c1c7d5efda8c8b0b49271ae80d32eb6ba1b22e40aff75a6bc4abe13ae0d7c28db8ae7b44cf09077f7814db8163d1b236c70eb34cea986a9830fb319f8303b23b887970f3cfcdcda9fae33b058c81374568d36465904e9643b68916dadbef2e955171d583d56da9ff22d7ae7d89691a3e6543a749602a733cfa263ef2ed9b7aa72e4b23dcbc4c119f6cb262e18ef708e3baf52d40ed8f89da2c115334a9605299006b53be36253754e7daf50b73bd68916ad1337aabb7782d361cec0a792c1add6e922cc6d11edf276e03b03861357029e21e370499494449418de22e6e69d38e7a59e7ace93d1392f53ab8a291b9e579ca8958df6cf1d29e7e7bcecbc48a5964d5218534615a497a5271835b2a784eb9863b63d0d4f7aca70fda3bd61b80d28623292c55b0c911a1993297546dd7dfe09fcbfb7598d1fc764cee059cfd3e32cd82b9c0f5a3cecdd3e78d87bd11d95a54d5891ca52df7931ef489e303f8fe149cdc1ffe5d3d05ad0cb543dcab3a1bcafbc0f27377341dfcc127eebd3d94eda007efe8c167dca194d3c662f3fa3adb3daefb3a4a75b585ddb75ad45d16925293953ca92fd0f473887e7766fc8294c36e647675696ddb63da7343d868d1931ab263f292cc5295eef4cb154ccad49ad2ac9d0a952cbcf60179b5d36c3f7d1f61cff1c5b414aa4ff8b8864fe3ba3386f5929ce9b9fd052f9d9ec1ee96cb6829fcd58ae2fac15575a5e8f9ce6155c893f7bb22aadbbf1e56bfd6f4b632ebde6d035e3fd5f27d52c6a3aefbc86ce894e21f9c6175795d1f0dc971eb8aafac2c6fcfee6ac3357e2fdc123908d23c98291d2996ac56e359ea822419dd0cbc276199c4c3af530a34fdf8aebc9d8a318f4f5021cd8a1c103d34f1c74a24f3de864cb557a55ff013e50a1149332197ef82f6555aa30b54ca60e53f9f7b2cbd0246f36e15b178d591de34c34a5c46a8e62c294e08851fbfdea5807bfbb57e3394783a3b743418f1c77c9db77276ab5264834c97b59c476a33156d6cb866db7b5c6f2d5cf07dd4727969ce0ca509c3cc2537635516330faef62953834b99c0f6d9fce92efc4fb5787834f341ac4c787b9fcf86268e243f5afd250358db8cf99921d1c9dfc091c5d31d4ecc88ace4e8deb151addea647d8e263b3bb9106fd476b7119287b566c76845b3b3d5dc6e08dea6fc094ea783083c16e0ce1dc7cf087c031ffa280fdead3ff6288f2c88941ee531d1f227b4a65c8733375123f85f921597dbb213c345ffab025a9dce1c93c6e5dc96ed765975afcbded15b334b53b7a6665935140a8d98f7fd33c670994aa7128bbe7f61d0ea4bcf322497a4f51f144a324aede159e97c57e291d88d7335e39d9cd7e3c427f74a7c725b84077c60c485a3df2e97eb1c9cd1adba21c1383c788ffef091cb9f2af2a18f127177d982fb169e8b4170380bcc3a979365a54d48a968af49f57f9ee78acc883fb7ab60445aa4f0f6ecf5b373fd8f0e1db042a92d9c7cee19c32785cbe5fe9d09aef28131bf8f632ec07356c51ed0080feec833641a0bf92fcd3acb8cfc774413338db8d16c2f2b8b2dc1c1efe42b8942d437f82279189325aff49d884d6aea8f3c2207b71d7a409ed86fded7d94ab3330b6d61e2c430b323c7317e607a7827d7b7ad6f2f4d1836a9303ec3916cf06854fec78dce11458b2f2828cf888e546ae4a24c63d0bd9756e28cf0af189cee23ce94e49af9b545d3c70e33682cd923535f4f340bcf26e6daa3fc9f46390af9cabc3cf0912c0d9f219990c29f87cba4e7e1ca9d1a679ba10db79e921ef939fc362f1fbaf5fcd2432e6dd4926d9df3b62e19a933e73b52f126b1944c76b9260e4fd45a729de939662ddbd4b5f1fcd282b9b75e2a9cabd6f37b45afeebf7f5afd709379f8a45aa16dc08691a90d7c283e279f074e28810df4dcf6694d257b05fe2f283942a75b139954ad2d4935c9c232068e2f19bd6c9c5b1d377ef0957ddc0e77d844f984e0e98ebf95497715ce289f1f85dcea5fd9c5d013f5b0e08fb3242fc4c40e7a43744a3fd68a0eba69b8f89c262edd624b8bd756dd3c63eebac6b48239d7cfaebd68043f663bf0987dbca8a5286f6c6674447a6561425e41918d0e3e9a706dcbf8a993576f6f59f2e8ea9a91650ccfd1d2fb8ba6bfb0b2266f6adbb0e273a7e587270f4fe351bd24705cd82bbe8aebf982e009da19de2b34b9759010aeb16a7234a25ed4e05cb7e30b99a6974d736bdc99e39de1d1b671d1d214711df369ce9e3593e51ce43fdfc0377fcd2f561f7208e253561a7fb058a2a5438442d88b7bbd4615156f8988cec8ce4bd4497337eb3409e9565b46acc63eaab838516fb1c5e17b9b20d6a6b812344a95d2983222abffb0865e8335e2b281d4fcfcd1ce7051a9d6e8a23370c5940afb848d0a2d9e8a8641be4f1d3f6c2ff3e25ac9663bdc06a3755ebc5a4cdb12b3207fab6e91b8906f3ffc061eb21af8a3e0df8e67119eca9373e2ac51caece61195334b1292dc4de5ae090efe78323b63d4072c4556535adcff61ef4b009ba8b6866726fbd67d87b6d37d4bdb49577628dda11b696905514893b40da44948d2962242a9e253e4814fc05d1f2afa044504041151ca565c5844012ba0e24396a722b83c4485f29f7b67264d0bf8a1ffeff7963f396472ee9d73cf7ecfbdb79316850c8ee58386c45027bd7c845285242795d14c308f28716853a2a2c840895c2c1088e592de71b1f161c939832272930745a7a0384ea676939f8a228854227e437418e1bd997c658c324cbe3d6166b47760842d101980b487fa796597dfd0bef939d0ff39680560bd2f243fa544728944aef255a942c2227ca54171e183e383e431e94c7450425cb49f57788044400ab78545c1a74828f58b0cea7d53a2402bb44242057ac16b380c900925523f1a3c7efaeab71401c530104e6c915ba17e6c266822905abc49218a1b54ee53044a7eb29f2f20dcb153c0fbd37fe04f783f27e5a1299006a172324c19999d989815a912a9a27292927269958ace4d4aca8952912ff0e92f58a40a5089252a7fd52f954943a2bdbda38724250f8df186a325aaec07aefe83ec115ab06e34d2ed19acdb339b143ec9a01d14b74ff6fbec1a58dd047dd56d80766fc98393e8a8e46059986c70764a4a66b80c76ee70888954a92233e313e0304336c85428315532ea90973fa8a6f4f7ba9c1597417b79d150cfb3d0671668d62e305047456dbcd70229316c77a328f1a624d1a0f8629f62f0dabe0c50ecc87515235da7b0789ca081d44e596074d8a09800598872909aa6d583e4bd6659404cd8a0e84029194ca2ce3c8d60317f8020b7810745702897f7e6f5ef0b0c247c880662b2f05661052121bc8960b43725d2895c6234514c541275c454a291b0126dc43ce2c8184b5593b9c63c64d69c1173126d4eb5939e668835484bca9465c4980261810f931590659ee334941564651594199c73cc92c1b74c09193ccede5ad13a76f6dca2b919d32d3996b0c9b747dceea7ad0daaa5868d128f9227a779a5b5ceb5dc5e3b2a2d6d54eded96b9ad92f886fae878227d5ffa3edf60d86de2976fa6cfbe8c5fbf906884df6f19811c1e139d9d959991c07dfa739fc1dc277f5f32a03df073e07d4950ff76dc00febc3cc121262b8b59862e3f666a3235b108ebcdcd80d79a4c8d2693d2a2eb9530d441dde5a2bdf232939591114b6ab2b234e41e74b3770abafe88a897214cf0105c1868f57e9499a9f90c1ae4c380d4226e77c0857c33233dfb4a0960cb19268ba239a25e092067d1b08fb398ac3440ae5e2542a8bdd42fa2b39418fd8d0468cfa2dea77688be80f646be2d08c2edd75cf767e2f6660255b759d4016a82e80b621091b64ee4b5995c3b461520931101aa1745225fe1cb215ba85ec297badab747dce5b65d47e7b5a04084f8a28acd1f3782a809fe5e97be57f8fa2abe4f189a9b4487901dde7ea2e52951cba213e3137b0f7879abbca8dd302b588df60aa3b1465d9c867ba997717bb7ab7d0cb7bb71db42ed10c8b1c5e8afb550bc0760ad4920c68c098e53797905c52b150a416c58425cfc565542a452298e44df69f327c4c8924c74f0f61b9a792e83443fe50bd907fbfaa1f8025605617bdccfdde841983ff780459099407d2b1225644727064b054c6f6faa4016101fa989178bce0b15c18931f169610ad1a1e7b5027f65b0385026808abd78a14c2515280244c12a6a9dd24b4251522f556ff91574e2e6a205b39b860a54b621d02f3cfe0df218218783e7f10d7e7ef2a8cde467637c087960f8968eb807e2a8b838c9e02d5e9ba9def5f15b249b9135fcf10f1fb45188f0e104c7073ddde3a3c2064a12149490158fe396e3cf23d48e9c647573c98190e8e8909d0ffe392775b4f69b9cd12959433313c7960f2d1f3a56b06df494f0f0b0b008eab9f0b07a537675b0efedbfa8e35fceec3d9e95b93d0962c06519789826e2b71201e467109a4160822c6cab0a693b68ab98d7d6bdcebb69071b7189db463c28d7fcd7c637904aef4c5f969995d31d9433299fc91851376490b0a1f9b1fa54561b98048bf4397523e8ded8b0e153703ee3fc26a28911eb02223793c7c7044842bc43bc0949c0d68e880722a88808a1ff5605d22972abb09f07dd0fd0f830da97d081f86c8a7d88b40e44393ed3cfafd78814241ff5f1f7f7e93d77d6cf0f6d98cf92817e7e8288d42856c3c8f4547a59646a7084af785d143be370bec36e7f0c1c3f09da4b1a151524465127081ff2d86b4151126f8122210ca9e82f5060153333476742f5c4aef3c33f9b1eeac7ef93404901da27c52708dc66217bf0e4cf9dc2e8d821d9f1db25099919c9a2d7e37372e212e89911291141b2c79e92050e8a0d752646535f7bfbfa7a53ca2bdff929bdbd29ef2bdfe3f686e81845506c48af965c131a13ac88892670bcf11c85bc8d269875919237c8e3840a72f6c41839a18adc0a0b59c4565f543ae4eea5a3dff132d05dd7bee8e3847c3979c2ac8aec8461431262c337e73626e78cde13169fe69fa6c91f2efc6a745369e219acda96c848dfa0f0466d444290ecd331bc5e502b602e6511e337c4fa44c9d1affe104432fa659f288d0fca07dfa058cd962eeff7bd4f780bbcbdfd99ad61a83688087fb636e01f5cf167c94cfc03babeb53f813dfe0e541dcf2c749414f4d9704c1c981c1b111b2013140567a40e46c644871c8a48f1d1d9c7158f4a1eab107d1314c7846a86e7e6535fc29e4e288093fd9a619ade7f60dbb68787519497f9b67263589ceed1d0404a3838da5fb23e1965105701e1741f07bb29703d4a9ce3eba5614a9c333d022ead335d534decbe05f50d080205f99640bef6d9f2d913d352b2b3d4650585a5c93959c942c5d32fc457b5d790bbbc7c7dbd7a474f1a5f5649be8b7082bcba45b2862a926aa07a49d781cbd333198d202a30aa885a74c529d5dc8dbf16f1140be4f81bc2d7ee404de4e0dcb520b8ebf783b0e8a660070291fd57e0d8ef0171de0de14d7790501ce8ae03affc7e90c6df147460b872639095ffafc0d9ff7e9037fc1bc2de1b8322d2031ef82f81e67eb0e5df0794320f78e0bf1b5483fe478851a50064aa86abe6f483bb312c025886e1090f78c0031ef08007febf869f553f7bdd0ef0acd70ffdc1bbd605cff80402d478c0031ef080073ce0010f78c0031ef080073ce0010f78c0031ef080073ce0010f78c0031ef080073ce0010f78e05f0e460f78c003ff29807f0f2e958a26f0ff644f10940fee11e0dfbaf6c22d01fefd65a9f008870b8834e12b1c2e244284dd1c2e02fc530e17037e91c32544abc88bc3a544b2e8410e9711b4e4210e97532b5cb21444ad6413872b8964a992c3555e62690e877b11e3808664ffba31290b1ac1e12421092ee4708a1086bcc0e10222386439870b0965c80a0e1701fe12878b01dfcce1126278c82e0e97128141f91c2e237c42ae72b89cac72c9521029a1de1cae2402438771b84a2208ade4702f220e680404299481727ea2bb399cf5338bb37e6671d6cf2ccefa99c5593fb338eb671667fdcce2ac9f599cf5338bb37e6671d6cf2ccefa99c5555e21b496c3593faf2268228360e0ad01ac9c30117ac24e580907bc1b0827f4e50366276cf8aa831e136016220deee41166009ad0425f23d104f71cb865844f2350b7c2d500942aa204b07ae831126d405109dc8cc0a38668c7184d9401e776e0db82259a016bc49ad0f0b6024d3b8ce565d02e9d192213fdb6b7ab954ba8b17c1d70b0012d0d72752007f1d0133338da71d06a825e74b705f473b8eca9817e13b6c17c437d1ab01f68622cb4d1dff046bd3aec85fe36b27cac9ca53496d20277f5d85edebb6d30d68e7b5a80ca80bd46437f13ee2b274a4127e41d131e67c17e1d8ec71b318591680699c8cb067ca5398d785a1af73b704c4da00b1fbd3e3bd07d27686182910ef0423eb6c6842d31b9ecd0c1bb1946b01ab2f6e8b00c9a8bb5093822ae3aa043bcdaa1d5069813c7c101f6d5036ec63ad9b12f90bd26b836729e62b93ab14dac4c0bb6488f35b560290e1ca7521c9506e841f9d8823de8c07c8d5c2c4cd826d6170e9c150ee0aae3f21545ccc6f5f3529a818f19fbc7c66969819e662c95e5e9c09eead30049b4615bd8b9c1fb96d5dd8cb30665421397b948ab66a0d5817c276e5970acf9bc667dc64a61e368e1ecb262dfd663ca3e8ddd2d425e9b85c7b156cf80761a9ebbeed14cc0dc9a318776ec87166e96bafb9bcf3e0b97c9c87e362e769c0d7c8e1a71ac51e6da5cd6b03a3672340e68cde6b83bc10a3642adae28e9708ea019d0dccf2ebef2e841131d96afe7e4a75da7420dbbc64e343badd03610b55cd6f0599f031c32e0da9f3ed5457fe3ec77623d0c383b914e335c71e99badd7d6ce462ed76d2e6a94cd6c165880de88f3e97fa706cb3d55f83fa60a9781267a2211cfbc24ee3e4d14e3acb062cd9c00a8860d23d2010cd8b76864f335d993c6e55c3ae0ed38871a7116a1d8b443af0e74677dcc7365799ab10e488306ac2d5bfb585ed7cb5107ce731bb69df5023f0e45751296c1569f76ec69d6334e57b4796abe56e8b97a8e66be1afb00d1d9b8ac70afdd36ec570b5733582e46aeade3eab411571913b690d5ae1eebc1477960c49cdc08367fecd7f434b86c50df542560570a03f6a9935b91d8f9c9ca55bbe40cb480adac6dd84f7a3c9faee7b336ce52139e69663ca7d8997fadefd11876b54904faa47e197c7deeac0ebfd7b7eef3835df1696ecd76e2c8e9fbad9d032de85b2907ea35dc2d079025ac2dec0e82af9576d76ec480d7630bae23ba1b5acae69eae5f56b1f5c0ca5d59ab58bc05cf17b63e19f0da66e26a0bcb07519a71f5bf718eb255dcc245a68f3b3f434c6e3b8d265cef4c9c9f515557e17a69e46ce0771dbc97fb67b51a4746877103c1efb906d6b981332171405d30e23add867719261c7d14551df4210f3502057f2f9de3397540ed4ce2666f5fb5e8db21f0dafc96d5e92657037af0001e653c0f3adc95cdd3a18f8d139f35ec8ec5ccad227dd9fd6b2b1c9f95375ee550e4aa5c33c7e1b64761e3cd66819193c5566c0b177735b6d9cead3efcbe82dd2b357271e6f398cd2b1bb70f622558f15e5c87ede4334547f4adf203ebd91f100b978774d876e4371357eb0ddc5cd573fb6f0bd6d57dcd34e11dba03e726a7e38d630b7875ff751ea29de4e62383dba9c17d3edc343fa2efa4c3535fbfbaa9075437def703479bf149c134c06e5eafbe3d58dface95b89f818aa09fec4864e667cdbe89621367c2633e37c6b725b6159adebb12e466ea56a71c5d2bd96b0314ce722eec0b3c4ecd2819fd7fd73e9e6bdeabec2b356baaf34fd73bacf136dd88fcdbf338efc6ad0824f9cac678c6e1a18f015c9ecf3cb74a0d0bbad1dce5fa9c76ce537600bf8156f58bf2aceeec65a317ebd5db705af11fc2ae37e66e3d789ebd594fea31cb856b0b1aae7ecbefe9aabbb4144ed2eeb1d384b2d983b3b8bae3d0dffde0ce0d7b712a210dfad248aa05507aba516f794421f0d55540b776aa15500bd05d0930014d5dcfd041ca93abc0e9500dd44bcc6b13cb470ad80f6245ce38a081ab7516b3cd057002f34b690b805cb28046ed598528b7997436f197c16727468443ef44c8436c28b711564e555c028f60c51caad89aca635d04fbb2cecaf552996c86b560e2d2df02fe1eee601ef52cc0fe98fe41761bcc2a56711a7691ef611e28c78e6834665b8857a27c26715d05563f979d86656db0a6c4311dc676d29c41a20c9699cad2c1df24f2d7707c508e95706d067551ef64109d6a6cf7ff9f059059a23fec570b706af109530b2005b5a8dbd57c8f90c595b865b7d56b191cac7d620af221f14005e0eef6297efb4f8caeaa275e3d6df7775f87e1f156b5f1e77cdc79eabc42d361af9b855836385eeaab9586ab11d03a5d6e14c2cc45479d8e26a578614e1ec65b5e7b3939551e9a6092b0fc5d65d173eabe95f99232c17fefe442ed2d7fa05793d0ffb04e955ed927c23ce303757d1194c86862e37e9ed5687b5c149e75bed36ab5de734592d69749ed94c6b4d8d4d4e07ad353a8cf656a3214d5562acb71bdbe84a9bd152d36e33d265ba766b8b93365b1b4d7a5a6fb5b5dbd1081a716632e978f491aba6b53ab3ad892ed159f456fd0ce81d676db2d0252d06079253d36472d066773e0d563b3dd6546f36e975669a93083456104a3bac2d76bd9146eab6e9ec46bac56230da696793912e2fada1cb4c7aa3c5611c4e3b8c46dad85c6f34188c06daccf6d206a3436f37d990795886c1e8d499cc8e3455bece6caab79b90101ddd6c058e20486771001bbba9816ed0359bcced749bc9d9443b5aea9d66236db7826093a511b40252a7b119465a0ce001bbc56877a4d1a54ebac1a873b6d88d0eda6e04334c4e90a177a86947b30e1cabd7d90047439a5bcc4e930d585a5a9a8d76a074189d988183b6d9ad100ea42e70379bad6d741378973635db747a276db2d04ee46cd00c8680911690656da0eb4d8d98312bc8699ce584c1a619c6349a3333c14137eb2cedb4be0562caea8dfc67012fdb75608bdde4402e35ea9ae9161b12031c1ba1c7619a0de44e2b18d48a4cd2d11081665616ca1e7d93ce0e8a19ed69ae8c1ac6cba4c75acd865a700df27d4e5a460ed79f8afafbb9df69d7198ccd3afb0c640b8eab2b3d1bc1eb36d4adb7820b2c26a323adac459fa873244128e962bbd5ea6c723a6d8e61e9e906abde91d6cc8f4c8301e9ce769bb5d1aeb335b5a7ebea21d91029509a5bf43a4783d5024e07aa3e618e169bcd6c82ec41f7d2e849d616f05a3bdd0279e444198bba9133f4105ea7514d1b4c0e1b64311b549bdd0477f54062844f1d84d2686f36399dc0aebe1d5bc5e724b80b72c76ae7910624417daded900b8616bd538d52b215c6aad1185e00c4a8adc9a46f72d3ac0d849a2c7a730b4c803eedad16c8964453123b37dcc881c3af69cb4e25c87788bdc36937e9d9a4e405e05ce4790dc71e483481149817a89ed8d1ec3158db2c66abced0df7b3ad655905d600e840f212d4e1b940283119989689a8c665b7f8f427182fc65c951404c78ae3499ea4d4e54a45435a0728315cd18a432e76a355daf7380ae568bab5cf04148e472c168496b33cd30d98c06932ecd6a6f4c47ad74a09cca159624082f4e0b3c0f109beb57c2eb55b00f388a3244f12172f3742bd8845c03f3c90cd50dbbbb7fad44aeec572d55aa2a141c079e486037b8c008a320b1c1330635dd6087ca87a6084cc646b019f9187c051185e1b4b51e2a9e05394587ab359f67376f055248e77058f5261dca0f986750b62c4e1d5b544d66f04c22e2d8cf5aba9a2bd71f26618d0cb822b271b82e1daeb5a8db2dddd45cba21edf9db6613e4292b1bf1b2b3cb1548c0930859a846f5dcd4803e8dd821b61630c8d184272cb0ae6f4193d7813ab92c010bd3c17087119569abcdc456d51baaca4e7810c94e1aced35889b6266bf3afd888a6418bdd02ca1831038315ea28d665ba51efe413ac2f8f21f90d263cf186b1290e65acd5e8b6ea5aac4e3465d8826ee2a6319b29dc2d47135a13ea8dfd66aececd503b12ef704232992044aed5e7d71c80e65b49215d5d59545397a72da44babe92a6d656d694161019d90570ded04355d575a535239b186060a6d5e45cd24bab288ceab98448f2fad2850d385b754690bababe94a2d5d5a5e55565a087da515f965130b4a2b8ae9b130aea21216f7529889c0b4a69246023956a585d5885979a136bf049a79634bcb4a6b26a9e9a2d29a0ac4b30898e6d15579da9ad2fc8965795aba6aa2b6aab2ba10c41700db8ad28a222d48292c2faca88165b702fae8c25a68d0d5257965655854de44d05e8bf5cbafac9aa42d2d2ea9a14b2acb0a0aa1736c21689637b6ac90150546e597e59596abe982bcf2bce2423caa12b8683119a75d5d4921ee027979f02fbfa6b4b20299915f5951a385a61aacd4d6b886d6955617aae93c6d6935724891b612d82377c2884acc04c65514b25c90abe97e110112d49e585dd8a74b41615e19f0aa4683dd89d3549e67039e6703bfc1b79e67037fdcb301397e7b9e0ffc673e1f60a3e77946e07946e07946e0794630b09a7b9e13f47f4ec07bc7f3acc0f3acc0f3ace0dfee5901cc4d01fb8dfeab21e8ff98bece8be2bea94f9089f05986bff1ff6b2fa1e061a592041ad279b3f42a15a6efba597a6f6f444f296f96dec707d3df72b3f4bebe987ee5cdd2fbfb033d7c12e8371784985e086f15befaa2ffff8a082306431d8b27b2707ed7c17c9b8cf77d36328cb8935c442c148c239603876760c4ea01bc5efe8dbcee075e0f0107a4ff4bfd799193dd780503af38e09509bcf28017fabf231b8017aaf49dc0eb01e0f557e0f52270d8022376f6e74585bbf10a055e89c02b17781501af89c0cb02bcee045e8b80d7e3c0eb45e0f51a70d80323de1fc0eb9c1baf41c02b05781501af5ae0d500bce603afbf00afa781d756e0b50f781d050e5fc1881ffaf3127ceec62b1c780d035e75c0ab0978b503f610f0fa1bb47601afcf81d7f7827124297898f407ff84a37c974aae4a25212123621be6363448c5d0beb4772ffcdb7b492a21a4d24b7bbbe1050d1121155feaea827f5dfd1a5d521921956fef3809f063c7e18e4f3ade01c014177a7a7a2e200a9e6b0fb0c55cbbd9d71c4c1612320b087b668905845878a20bf3a448a9106344579740404a452b56acc023870c319bcdbddddd5231e9a62934a408c30d11e9ae29e9ae2929555ca329c768ef25ac29e9a629e2ca32dd3b4b26266412a5523907b5e68885845874012b28a34819ab2ad65544c8c4608c4c46c86483211639007a8079c4f68eed1d323129c38ae2b74c42ca64ac83c1c3e89ee47217abebe57ead2e998294a94ec0ebdb1307a71d037877da7e00173bac7c1f73a4bd4c4acae43bd957c308b998944b79f5f7ce91084909a77f979c22e5a22e970542112997a078c8e5845cae2422003201741df300f0000929975d8618a077ef65b99494cb2ff7ee4182f6401349ba0c9a5f029d2ee3a6846fc2582529f73a61bb00af8f5f41708039c07403b89802c77e32c0a0ee6e2c8333e6ccdc110a09a99089e1d58a07b44a44a444dc830574292852c19bc3d9a3c0f628648442ce87240787840dcaf60e859454c8598b4040ef65858c54287a89abc4ce8eed2ed8d97195e8259068696f2f320df8f7f62ac4d0c638be742954a4c2fbc49013432eccba80d37adf23fb1e39f0c89e903d2158eb3e13bb5c52bb2f5feeeedeb9134bddded11f4e76cc2346114a09a9ec33182cc679dd73899d2d4a8a528abbfadbacc4362b158452e94578419941a0e9d074cceb9ad735ad0bfe4d53ca49a5e22a719593e486018e6e2a7b715797db0bddec65d5414ee0bd30a00354f22295be27069f187c61c485113de61e334abb3d8bf62cdaa9dca9544a49259b317b584f2865a009f637865ee232d18d31a40dd6a4eb9ad7e75df33a46132a29a9920be0357cde19941bf386cb44307178cf74a9284ad5e71ae41b91885449916f7af08ac6af7768bda70c664b2387a73958bc16e179765dbd9aceb3375bd4747ebbddaca68b8dd619f86a87abdd08387ab8a4a6cb744ecb6fa3c63a90580f78c73d009f01ac4a71f7329d71778b65c9f794dcf3a38a94502b3ae35aa06b2645921a6f4625964dbba784340a84142922989962798a9814929db914295ca167748cdaad67f033111d838911182af151c88a7f38818ecea310309a010c85f48934f9e985ce8f5e22360c4b78688960f653f5c7674f58a39f96bdf04afdb8978fddb9a253319de9147ec7740a8eae10502445f967c26640fbf9cab52756ee7eba016f18b4882d67014c4c8299ab513032b160a250ec4f4dacd6f833bea821f597d7e91c4d264ba3d36ad1f8305ea853e22fd11a0dcd568b4113c10c463d72ffc0eb7ed54393c8c4a3fb02ff48f7fb06235d6d6ac40f0babf2f3e80c3092890856656898a14c866648468e2677323433a0a9e19a8cf30fd18fbb2fb8c17da6938c767714f85fd0497a13d02fa73a61c3b571e1c5478907278f3efee4ebe3bfb48f6e3497db53a6767b6dad7ae971e562a1f59d4ba60d27a7d6fce5d4ed91bb96d7deb628cda6989036ae6af63f37749a4c1f7ff24af7df4ff54cd4386bdf5d94296abc5793eb939d3068546c80aeec6de7fa7beb8615c837533ffdbdeae202dd376b4729b58bbf3bf27345ed9aa1db4b3bd73c9a9bb0b461e45d6b26bcb969b6a3f2e0579746373fb456593ca1b86ce417db1e7a33f4d5da5b7c6627dc6a0afd5effa748d108f395f35f5efa786dc682178eee787a4a7efb2b9396bd13dd73f034dd342ef974f79367eb74b5673a5fdcaf8f3e67a9b7a6efeeac3f2f3cee4dcd558f9cf86963b362993ee98e6f1f5a1d72b1e9838bb93bcf8f3c38fa90cfe5779a0f3eeb4f09608a3cdb49ce048f3433fee0cbf038a192918ba590e22291442060c251a79730481830eea5d007efec5ce5a01a7a6ed57ffc37afadba6ff44c0dbaed2b2c67c6af2c658a35a94c0a0a88c23fb62f20a576a3193d79acb419d9b038e832f474d668d0043101885ce4afcac8cc189a3d34252b27372b379b89445c6384214c5047c0e9cb53ef78239ab8e50b7bc5c61fa29c3119a7cfbfc4d4228248612503825794ae28bea7907b50afb79b077cbbc336c3847ad3b9ef4938d24133c861c86048dea928795399dc5426270d8898c9bce52429ac60ca98717c9ba1ee19c589686b6bbb9e08a3fd57793b1925d219b6f9578514430c98bf02948dada7664f70ae76ec7ef6b5acc28ab4c91bf28e972f9cf16add73f35abe5626bdf1f9c8653f8a8e9d593a29e0fc92fb8b56ddd1d1755777cfb4f76387c6de3b7ce7524dc4a1ad0fbe9efd53aaf8f4bc4bd3ef6d7ffd646b529cfafb537f4bde79f58113af2ffefaaad1e7f3dce74e1d5e7a6412a32cddbcfa7191ec48e0d79aad1fde567bf9c9ecc5a7fffacf91ef4e4e587e79416c9a5f9dd1ef90b0f2e72afac80b1fb5dd7fce29acdab478d75f965468967c1930b7f8f02f27822edaa64e3e10d9117c7ff59ddfb7126f3d7b71d694d35fde7d47c9caddabbf7ae10d8938ececba83e78feef8eecb1fcb72477e1df4d924c3fa84edf71ff499d99bb06375fe5f576fdcdb547ac6665c362e7357a8d7b9af2a8f87de3ab387e914dba0f2ddc2563db94ea92dc3155b30b0d8cdbff70fa926190cc35693a4befb5aab158820b6a606935ee734d2792dce26abdde46c77d53db8e63239194c16c3d6bd6cb6998d9afff2bafc3f55c07f7819aada1b37ee3a794546943db5eca51f6b9bbe2ce839b0fb96ca55cfb5ce692edcf2e1d0075f5d19f1d34fc6ce2f823f5872a5e009e959e3d2fdea89776fbb537a322de585bc9490d79e196f292d9b1128f9f4e0073bee8b98b96cdfc679e35f5d2bedd97bef9119c1cb862ddd1f3ffaebd3bd598fd41d0ebfadf4e2fae4b4c30bde9834fad203afa6dce57c3765c3f0a293178a4ab70737d4bc33f8cdf05d13ebebec971a5f8fa3b33ebdedf9e796dffe6262c7bec3eb9f3a25d8a8ff707dc0dbdbdf5e182f9f344ff2f555af731d7ed9657ecfbfa5bdf59fcf1f3d71bfa2a4edc882e2c33eaf779f5dfdcdfdd3534553a675bf9a7ceb133183a7169e0c0b88b0e6be179ad931fdbef267a737e8672d3dcc1c581ec957c093e091cf181fb18c5bdb0349216421e156feae5b87425d030228a132424e54e31f89e613798c028df4162236f730deaeb92f6204f0d1afc21dbe58fbde92b3cf4ca96f3a3872d903b77eb4ffb1905dffb7150ef216b2169295ab4239a91999ffaf2adc0d783b99f94f22a569e1fce5ccfc0799f94b5cce491330f3e7332379511419a4b9a1a8aaf1a5f84b7ae9f955d5e9066383aec5ec4c6b723633635cc329262b22830e27ca609bd5887fe63c95a8c25b2ff453e4766855734f4f8cae67486974f8353517021ce63c5f579974c7aea005b336577d187d59f6e44b9d0f5fcaba9aac7e78b9dfa92fb61dd8b6f4ed9359ab8ecddf7c3c8278eb836cebda53f3da97b79da20e7dfb55cfbe8a8841ba67764c8e09bbb0e885fa09858dd293a347442cbdc42c087e7be898e73ff2da109574eab9a74d8ba297ee753e72e6e9e2fcefaa5feaf2664cf37a3f88a39badba0f3f931cfed84ea84df7b48e9c70ecf9a125efe4ea9a259f5487bef7b723ba1ddbfe7ed78bde27663cbefcc89d89135eb96fdc84958f99df7e2d725c989769d547c7b7cf3d586a5bbd69cd1bf6627df0cfcf1f79e6f97bbe7ec1a7e071fda6f5a6fbc47b8aee991d32faeceef0a8c377fc44c5a4eece7b6f5b78d9db41e7d73d31ef72f4f8d28596c093cfcf6bbdf56075fb5f163c79f88363231dd9df8f78b966bdb6787ad76affe51f2cf63dfa68e3ed198b7ec95d70f078cb8227fed43db96ec18e6d9fa8962c7a3cf5ab57bf3990f0e1c6db4d3faf0c12927f8b6d741c28afdcf4a9a8f6e1d93ffe435bfe439ba87241778fe2dbc5e7c6ca0eaa5a4fc6d4ce8a8ecf79ebdd758b2cabc3bf5870b438b37ec9ca77fe92397566c498b58f18df893e3b362a6ee1e0d4691fe7de97775f7290f747ba11cb9aa669cf1f297e7445c7986f02e7b78d7ae24475485855f890e58f473464fa270c0d9ef5a79cfd153ba7aeffe7c8e2ea4d274e1d53e846267ff4a07a7feee45163c66a5646fa4877d43eb12df6b609d493d3db3f08fef0e8f6658b2577c4cd2c78513cfdf4a1eecf621e7ba865b7a6337416d319ea84cd3f0369fb2f2ed737dceabb9d2056cc7f05951d2e9165028dd2fd88029af4b5141a2fc6fd6e2093de3750a88916d2677ad3db94c326d57edb3e7ba1ff903d0b9f381a7266cae7f9b35451af075f9e78fa69a6c06db85293c364ad08e8f0bbf6ab2e4f0fee08e3bf61db76cd9c1eb002093b49c28b5e745bc4c64767be7fbcfcd1d7e69cdf77e58b7d6f7c1a2c7f764eebf1cf4ffc3d7178c6773f91a72e6acf2943de58f7a56842c2d4a85b1f38fa55f52cb1e6c321c490170be7663c9023f8b0fdf34bad6d67b746066ea3ad21afa52c2e9f3e6ecbbe3ce516b9635de678f384433977ed771a2464cca7938f5685b6f59c3bb76ecbf1d7879f2b32b53fe23d6d946dc6d2f82dc6dc15e74727693ffb71e6830b96bf15975cfdcbaafaeae855bb820f92dfa42d31979b366e3db76bcf24baf5b1d39797c9de97bf959fb9e2db157255cf5b62c2ebec88ce9277e9ecc890c3c32c3d13fccfb457191ed9e4d3d1bad2ee7dda611bbc3be7e09ff3b69f7c6379e1da212fde31aaebec8e95676216eeafab981bf87467302cc241975dee1508484d67d0d7d077b6dfd934e863e83a4c91826bcfa69de404b1820fa70f1c4f3bc931e0db11706308e433c7faee497201799d73e80ff1018a279e7b7081e19fdfb6dd71720a2d2f5bb4e183e599ad472fb6fd6359cc9a424aacfbf9e8e694ef42fc331838cbc1690e5db232d23287644c66841d14f9c38af9efaf9cbf8f99ffee1f326be29818f62c31b8ef7e5eb3d10efb30b7b384269e8965c9c26b9a74e85ba635d5d5746175c5b021794332520b33b38a52871614e4f1ec04eeec6a4ccdc6d46aa7aed94657b3df9e5ed1e95bc7744a94b00ffda1eff44d3efaf692b56b36ddf9d6fdf827e08f0edc90cef9431cc05926f00fbfaec6fdcfde1af41b1b43996c4d0eda836642c88670cdffaaf8309dd4b51b5a0a6d6829d8d0c282bed9ffa7ba29cfaadf3b7a7846c3d6e6a01fa86d07962c793c99a633a8c7debdb028e8ce4f9cd323bf3db5a063f9aa2f1e1ef7e7a6af9e326e5c7bacf8b99d171f98acbffdc965ad9b7f3a3dbc3dfbde8d4cc194150b47f95beb36ab45c48ea9af365ad7353e76f98bf747cc371b0a57fb7df4704be8f177a60c7eed89c2bd7ed4a1e59dad8dc7cf45dc59b023e32dd1b331a373cfac7a65f6a2d861ef951ffef1f5e3cfc8befd69c6b4ceb7f366a80a762efd6c68d7206ad0c5b2fbcf746cf9f323bb777df1f22b0df113bdef59fbf3a363c65e38923cf3e27e7dd695f1e396aeba5343069d5fffc333fbc47a920cf51bb56cf703ba8c50b5384cf8e4b0b4f9d54f57a67cf3f29abfe67e30ece0ecfacdf16365170f452d6b94de2dfddcfebc76d3bcd7beabf93fed99793c94dd02c71984c93244961232b6f2ea19d34c296b591263df622cd9c6cecc205926c65264274511927ddf779122de92227bd6b2247b96182e7aebf5beb77bdffbdf7b3ff773ff793ecf39739ef3cc33cf39e7fb3bdf31d7fd3a64cf2cce1c853c43abc3939b626f595d8889a6905e3cbd744949e1b5bf296de1dc2b1febed7739db5cf956992b1cf34c03fe0398b72fde45e5648715a560e90a2ba40568b3b572b5ef9f8de5be2860c4c56d30ba26c6f1510e7d18729af65205d7860c9f0fb1bdcb1d2101bf89de0cb253e329a934d254f64d5d42103e108c15e6ee8a1ff262b52de6cb945e157d6048110be4c5ab0fea659473b26d08ac946e8e8cc6f6e95fc43b9777998da53f63f01ae9f5da286a4b841184318190f0367fb060cf303138ebfa082f8de230fdadc5b5799cde6ae551c0ade99a434cfdb546439988d0be839c12a3f26a940225e7bf077ae4ce2a28b62fbe8756e956483db0cccf5be4ede864640e6a427041fe90c21fa6b31a91199b19f92d7f7863997e440bc13185034cbea5707d4017d04ed24c520f54fd7711d9c919bf17c47f0c607e31e0f721bc53d899b2fcbbab280c108209efc571fb7d71dc143006d0fbe2b8fa5fdeeb7b22ffcfeef66705f113df43f3b38c8c2d36e0aa0d2a40e5854e14379c818c3c2f28703d222ed9c1abaf9e641673bb2204d9319b3687eef64abc7ea33d822492010c4a23c2722a4b5a62d3a7dd437d64a3f11dcde8a88c526e7fe32b305b7e45441df6808291d166907002b96c0938e67ab3c1af2e8b2751bf76a91b3298daa6450540489d66da75c7c971ca349d63635c3d4ffc8fd26cb8048be904e35b8003708a66d2f2e1f7c12fc4f86414d9a95d222cd97a42ebd33e0ade85d694f960c87a46fad1a635caf1188c9342f6bbe8b5527490eaa7b23c927322ec7cb7ffd22d4ddb9a0ed48aaae0fc203485327531b8ee63f2d52fb70b57b263c8120bb0d522f5a4fb145e9417f5e67f899732cf4f3ae4cdf4d45521fdc2dd0caa5329ad5ada5310a6ea1629952779a4b8412bdb9955c61adf4c6d1e6b294e1b54b4ea103ad14bbc3deb70063de8a985d8a90465b1547dd3b35b4a4a87bdd9825af44eb5e7ce3c8a7f810b7c49d33729e8003e9bf3105a1350bd269161e0de66f2e9575afd94b06265871e9089a9a893522109a746ce2999b80d65638a145d6a5c272db47e70856e12ef367bf589aae8a104dc0714eaf51f7751c3390bdcae49d92cbeb1a5f490616bd6e11579ab5f1fe078dfbb2bb846933a6b9b3d15c6ca3b3bc76b926b216c2ee2c76de4ad6a2d73bdb3464dc7c031dde17cac5a0fca5d251fa927821b6262f4d0ca18e9bc14cb516d1496ba7cac66878758804875e5771e92b13e9bb04b04dd578adb1334acffdd8266574cc301d859313131c40e1ce1c0b7227cb7f837a3fbaf68363e92a6325182e33d783da5ad1b7abd96a18bf89634fb809afa4da6bdaa6b4b2b426f85fc86fde5e1d1da4a293653f8365aadd96af58e16d6609470d960ab02890950e0a32b0d3dd47e4dec09847dd2d4db56d34fae3c2d4cc18e9a65e999db9740f58106b9162c5a037626097cd631f47337638f809697f85590475316096793cf959db382ac430858f4dd3b5fc5e909cff5312484408e26686e954d9af10fd832b61b2d6f8569b5bf9b09d045cd0dd684a68e458617898b683c9872b6a16f45fee21c066b4108d58e95dc843e1d7e114e28d50e1ff84aa573cfc1fa7cbc42ede7d43c0fe133396d9ffce427141c5bc5ba9e040268359151b3a29795a3a1b7c66373c82f57d76133d90c31a6efd7a2228f71499278daf1deb2f10aae2f9b4c4e0f3207bd233de6f1266cf626ca0f95e14ef57b9bf854f567119033489595938e19cc1a93f554148f3af069a8332e31474f1319e7218be58aec9fd327e3bca455faf38d1b97ba7af09217551be0e22a61a09a0bd6a290697f0d85d18e5a5b7683abe4f8564c8a71b7901b6814ce8eeb4ee7996ffcca0cee3677a27b81b4b86d9894e6c76b6402b844c6c4f454aaaf1f0cbaba843c8060f757ec1f38d2412aea3cfacc6e05ada961c4dccf5f95af4ee561ff8c890b3717baaed914c016fd4482b59ff34c330d2bbbb47bb67cd99763378dfbc2130fe36c9ee77996974bd98e8ae67ea7d9e00ecd7a01e6fd7a8a6aefb39dd0f4a30eb4cbb913e99a5b164df175c448090584703b64fb14e5ec3e0cfe9472e86fda4607d002340ed0fdd69d8a9ff7ce9e581690de676de07f4524b95d71a369e9ec84b77171c25ddff3363fc5ccffc5d97e71f613e826e8786f9ec81d11e1c690c3a086238938e5cd4ca769344b9994aaa2857be181e8bb923078a97877231629dd6761eff5da55dca19a1136de18be61df911cc37e7c76ca0a734e0b3578afaaec987b0f52f4412651978ca280aa2e68d266b88a76d673c8d6a94eb8cdb147fa922b792ffb7b0722dd17073eed71772d57a85ee5e0c3a530c9e74bd643962ba9ba59ab77ca8474045f436b6592ea39ca9899998c2405876562cfe6acae0b073dad612bd00eb850bc4997789b236862fea0ad6fa32fc7050e4dd7606423d7d3ab7851113b4f4769115a7796a9c8a24cc321a5472e743533913e6f243f5e96b23aaf561df8558cb33776397c25927ce5d57317d28a0ace0992ed0a3c3b5de0d1a3be05d61f949168d676483077b92452a8aaf84b030b25b6de621d5a8777680da3ad2d26d753d2b6e8c577df386628471e66c0116947ff30556800c32104ad3aab1cefb8c1ab6d672bcfa498b9509ed7321964ac96f0e6b58a5ba99e366da10db91cc12bf9aa3d7e0b5c3d236b2569436a6b90552210a2ebdad6ce8f97b3d697bc927a0cd3f0afa9073510533cd9b85883429db7264a5f0b71061d0c47f655a9acdfdf064f9d5e8322302787e92b3e86c4bd1b393e3d2f7841923fe6a38b8ba16d47a2d46742120cee5dd336e5597fd659ae2362a125fb5cf0391ab31bbdcee65aa8d059a2c3632a4803f6802da4844b07ae5f9cec6cb5984c04bddac1c0993d31b596fcbfb7d34ee103ef3c1af501aa930c14204e0a56b2a8b925b3c989cc2cd424b33790685e46f629e65392af1fe0eb934af89b31bd6f7e52519181a8c83ee4458700c7d919bfa9919d167031040018fca880fd56015c03247ff73094e4b0533bd31efc5b07bbff2f80770e20d09137a09da58d7aef9c29ee5b83fc0f74bb0d90fb2e07ed9ac41f466f57ec8092c000cdee6514d4c93cc9dfcfc90393fef495297c7dc9e41eab46eab6de7f3bbd49e767a8ee209d13a2dc8a9131a2a16e986dbe653f5e74b78d8df7e136256606bbac332dfb45b525d8c0905e3e7d369ffe2aa1c87f8bb3771942d6ab864e69e0adcaafb21e32a56ce1e3e566cc99f1d07e857795bc1e58121e3e4d29055ae0a6a6c9854690e36fe68932c57962c234273f4d98af4aa8c18894f4009192766f4447ffbd6ff45f5a9dfda295487e19e0dc6f5ae9ffa0dbfe49a6b2943ccc20039cfab9937d5805d2a3c68857622ca498c6afd51753f32ea7e77a02be5ff775003a05f39d067c2700df71c0b79692c7cadb667d3125f4b36526159221f76229154fd483476d0717aa9ff0ddc29bd91300df7bff0553e1e73fdccec39f1b980c6b690617ba9b6cf4f3f07f4c65d7c2905683fa93fa604b6f6a83a6e17f621c251144f6e039bf798f9b404a7bcc97ed87c716857515bcca0bf5928bbeac76990df4edb04e51a640283298f162885b34becc71dc7fcef1f1f156f90cc9ce2322738a668ffaadb1dcf2fe2153c24fe6c4f95555a6f1f70e86d5a9a120751be16a45d90b1fb150becd43964b506e860a955bb78573abaf9d98cd5d21a19c5fad4776de4d43be48bf97409a7f499dfda8d1fbbd9b758aa2e4b32582e0589f637f3df8a163f8e13b31c2fd1582ed0d63a008f1b7ab66d4ecba036160d89abe000b151f77220b8a321e7565a2c7c7af1517aef7f54eec769324a7cbdbda4f064dac874c73592a6473b6c9dc82bf505ae4757d3ea5df76833762ea5af8fa146278149b72d81eadac3694ff84cea092a3c913b3c847936d455ff23946e388b49cec889f28e2820142f54453bc3a071341e9ab50c48877b99e77e22fe73f2d3204149808bebbb22c8d1c437fc6dbda3d8acef1cbc865545be5699fca6b3f8db247be5fcae05341f4556c1d757574392439900988cf055acedccc3b32f20631bcf28c85536552d39738c39a93a02dab00768a0e748863ca7afd54584b69f34aab5c2632b44e19c3c078d9184c5c78db7418d3f4c8c6c0b1be83a6f6b843c14b8113e6c3b5351e08890508d72bf0ebc54c6c086d716bc32adf04e698a940aa585a5ef9e3de85a15b0a6f63c5cd1bc2e3ec9fe278b00d4e21e1e7a4c974dc51cd5903d2ec437c2fbcc21a841cfe01ef6a6b860d0a656e6473747265616d0d0a656e646f626a0d0a32302030206f626a0d0a3c3c2f547970652f4d657461646174612f537562747970652f584d4c2f4c656e67746820333037313e3e0d0a73747265616d0d0a3c3f787061636b657420626567696e3d22efbbbf222069643d2257354d304d7043656869487a7265537a4e54637a6b633964223f3e3c783a786d706d65746120786d6c6e733a783d2261646f62653a6e733a6d6574612f2220783a786d70746b3d22332e312d373031223e0a3c7264663a52444620786d6c6e733a7264663d22687474703a2f2f7777772e77332e6f72672f313939392f30322f32322d7264662d73796e7461782d6e7323223e0a3c7264663a4465736372697074696f6e207264663a61626f75743d22222020786d6c6e733a7064663d22687474703a2f2f6e732e61646f62652e636f6d2f7064662f312e332f223e0a3c7064663a50726f64756365723e4d6963726f736f6674c2ae20576f726420323032313c2f7064663a50726f64756365723e3c2f7264663a4465736372697074696f6e3e0a3c7264663a4465736372697074696f6e207264663a61626f75743d22222020786d6c6e733a64633d22687474703a2f2f7075726c2e6f72672f64632f656c656d656e74732f312e312f223e0a3c64633a63726561746f723e3c7264663a5365713e3c7264663a6c693e706a336738367a7733406f75746c6f6f6b2e636f6d3c2f7264663a6c693e3c2f7264663a5365713e3c2f64633a63726561746f723e3c2f7264663a4465736372697074696f6e3e0a3c7264663a4465736372697074696f6e207264663a61626f75743d22222020786d6c6e733a786d703d22687474703a2f2f6e732e61646f62652e636f6d2f7861702f312e302f223e0a3c786d703a43726561746f72546f6f6c3e4d6963726f736f6674c2ae20576f726420323032313c2f786d703a43726561746f72546f6f6c3e3c786d703a437265617465446174653e323032342d30312d32325431313a35313a30352d30363a30303c2f786d703a437265617465446174653e3c786d703a4d6f64696679446174653e323032342d30312d32325431313a35313a30352d30363a30303c2f786d703a4d6f64696679446174653e3c2f7264663a4465736372697074696f6e3e0a3c7264663a4465736372697074696f6e207264663a61626f75743d22222020786d6c6e733a786d704d4d3d22687474703a2f2f6e732e61646f62652e636f6d2f7861702f312e302f6d6d2f223e0a3c786d704d4d3a446f63756d656e7449443e757569643a46323633313532462d434344452d344639442d414533332d3532313738334235353246353c2f786d704d4d3a446f63756d656e7449443e3c786d704d4d3a496e7374616e636549443e757569643a46323633313532462d434344452d344639442d414533332d3532313738334235353246353c2f786d704d4d3a496e7374616e636549443e3c2f7264663a4465736372697074696f6e3e0a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200a3c2f7264663a5244463e3c2f783a786d706d6574613e3c3f787061636b657420656e643d2277223f3e0d0a656e6473747265616d0d0a656e646f626a0d0a32312030206f626a0d0a3c3c2f446973706c6179446f635469746c6520747275653e3e0d0a656e646f626a0d0a32322030206f626a0d0a3c3c2f547970652f585265662f53697a652032322f575b2031203420325d202f526f6f742031203020522f496e666f2039203020522f49445b3c32463135363346324445434339443446414533333532313738334235353246353e3c32463135363346324445434339443446414533333532313738334235353246353e5d202f46696c7465722f466c6174654465636f64652f4c656e6774682038363e3e0d0a73747265616d0d0a789c63600082ffff1981a4200303885a0ca16e8329c6c7608ae9119862ee03532c4d106a3b847a0394076b678250cc108a0542b1422846080555c906d4c77a0dac9dbd044c717082a9840a3095738a8101002eb80c350d0a656e6473747265616d0d0a656e646f626a0d0a787265660d0a302032330d0a3030303030303030313020363535333520660d0a30303030303030303137203030303030206e0d0a30303030303030313633203030303030206e0d0a30303030303030323139203030303030206e0d0a30303030303030343833203030303030206e0d0a30303030303030373338203030303030206e0d0a30303030303030393130203030303030206e0d0a30303030303031313534203030303030206e0d0a30303030303031323037203030303030206e0d0a30303030303031323630203030303030206e0d0a3030303030303030313120363535333520660d0a3030303030303030313220363535333520660d0a3030303030303030313320363535333520660d0a3030303030303030313420363535333520660d0a3030303030303030313520363535333520660d0a3030303030303030313620363535333520660d0a3030303030303030313720363535333520660d0a3030303030303030303020363535333520660d0a30303030303031393038203030303030206e0d0a30303030303032303537203030303030206e0d0a30303030303234363936203030303030206e0d0a30303030303237383530203030303030206e0d0a30303030303237383935203030303030206e0d0a747261696c65720d0a3c3c2f53697a652032332f526f6f742031203020522f496e666f2039203020522f49445b3c32463135363346324445434339443446414533333532313738334235353246353e3c32463135363346324445434339443446414533333532313738334235353246353e5d203e3e0d0a7374617274787265660d0a32383138300d0a2525454f460d0a787265660d0a3020300d0a747261696c65720d0a3c3c2f53697a652032332f526f6f742031203020522f496e666f2039203020522f49445b3c32463135363346324445434339443446414533333532313738334235353246353e3c32463135363346324445434339443446414533333532313738334235353246353e5d202f507265762032383138302f5852656653746d2032373839353e3e0d0a7374617274787265660d0a32383739360d0a2525454f46	2024-06-21 15:37:59.69054	SIS
\.


--
-- Data for Name: area; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.area (id, clave, descripcion, estatus, operativa, sede_id, responsable, area_padre, telefono, correo, horario, ubicacion, puesto) FROM stdin;
5	TSJP	Tribunal Superior de Justicia del Poder Judicial del Estado de Puebla	1	f	3	\N	\N	\N	\N	\N	\N	\N
4	CJA	Centro de Justicia Alternativa 	1	f	3	91	5	222.240.86.14 / 222.240.89.14 / 222.240.89.45 	mediacion@pjpuebla.gob.mx	Lunes a Viernes 8:00 a 15:00 Hrs.	Edif. A 	Titular
\.


--
-- Data for Name: clasificacion_persona; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.clasificacion_persona (id, clave, descripcion, activo) FROM stdin;
\.


--
-- Data for Name: detalle_persona; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.detalle_persona (persona_id, clasificacion_id, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: estado; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.estado (id, num, clave, nombre) FROM stdin;
1	21	PUE	Puebla
\.


--
-- Data for Name: formato; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.formato (id, clave, descripcion, version, activo) FROM stdin;
1	F001	SOLICITUD	v1	t
2	F002	INVITACIÓN	v1	t
3	F003	ACUSE DE INVITACIÓN	v1	t
4	F004	CONSTANCIA DE ASUNTO NO MEDIABLE APERTURA	v1	t
5	F005	ACUSE DE CONSTANCIA DE ASUNTOS NO MEDIABLE APERTURA	v1	t
6	F006	CANALIZACIÓN	v1	t
7	F007	SEGUNDA INVITACIÓN 	v1	t
8	F022	ACUSE SEGUNDA INVITACIÓN	v1	t
9	F008	CONSTANCIA DE NO COMPARECENCIA 	v1	t
10	F009	ACUSE DE CONSTANCIA DE NO COMPARECENCIA	v1	t
11	F010	ACUERDO DE ACEPTACIÓN 	v1	t
12	F011	PROTESTA DE PROCEDIMIENTOS PREVIOS	v1	t
13	F012	NO ACEPTACIÓN DEL SERVICIO	v1	t
14	F013	ACUSE NO ACEPTACIÓN DEL SERVICIO	v1	t
15	F014	CONSTANCIA DE NO ACUERDO	v1	t
17	F016	ACEPTACIÓN DEL SERVICIO DE PSICOLOGÍA	v1	t
16	F015	ACUSE DE CONSTANCIA DE NO ACUERDO	v1	t
18	F017	DIAGNÓSTICO	v1	t
19	F018	CONSTANCIA DE NO ASISTENCIA A FIRMA 	v1	t
20	F019	CONSTANCIA DE NO ACUERDO EN REMEDIACIÓN	v1	t
\.


--
-- Data for Name: instituciones; Type: TABLE DATA; Schema: core; Owner: postgres
--

COPY core.instituciones (id, clave, nombre, direccion, tipo, activo, contacto) FROM stdin;
3	DPP	Defensoría Pública	Periférico Ecológico Arco Sur No. 4000 San Andrés Cholula, Puebla. Reserva Territorial Atlixcáyotl	\N	t	Teléfono: 2222238400
1	CJM	Centro de Justicia para las Mujeres	Av. 17 Pte. 1919, Barrio de Santiago, 72410 Puebla, Pue.	\N	t	Teléfono: 2222405214
2	DIF	Sistema Integral de la Familia	5 de Mayo 1606, Centro Histórico, 72000 Puebla, Pue.	\N	t	Teléfono: 2222295200
4	FGE	Fiscalía General del Estado	Boulevard Héroes del 5 de Mayo 31 Oriente, Ladrillera de Benítez, 72530 Puebla, Pue. MX.	\N	t	Teléfono: 2222117800 
5	BJBUAP	Bufete Jurídico BUAP	11 Sur 4701, Col. Reforma Agua Azul,	\N	t	Teléfono: 2295500 Ext: 1600
\.


--
-- Data for Name: juzgado; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.juzgado (id, clave, nombre, materia_id, tipo_juzgado, sede_id, estatus) FROM stdin;
\.


--
-- Data for Name: materia; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.materia (id, clave, descripcion, activo) FROM stdin;
1	C	Civil	t
2	L	Laboral	t
3	F	Familiar	t
\.


--
-- Data for Name: modulo; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.modulo (id, clave, descripcion, estatus, modulo_padre) FROM stdin;
2	MED	Mediación	1	\N
\.


--
-- Data for Name: municipio; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.municipio (id, num, clave, nombre, estatus, estado_id) FROM stdin;
2	119	SACH	San Andrés Cholula	1	1
1	114	Pue	Puebla	1	1
\.


--
-- Data for Name: permiso; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.permiso (id, clave, descripcion, activo) FROM stdin;
2	C	Consulta	t
\.


--
-- Data for Name: persona; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.persona (id, nombre, apellido_paterno, apellido_materno, curp, rfc, sexo, email, telefono, calle, cp, persona_moral, estado_civil, fecha_creacion, usuario_creo, fecha_actualizacion, usuario_actualizo, hablante_lengua_distinta, representante, celular, edad, ocupacion, escolaridad, identificacion_id, num_identificacion) FROM stdin;
80	María 	Suárez 	Cruz 	SUCM000000XXX01	\N	M	\N	\N	\N	\N	f	\N	2024-05-24 09:28:46.174	SYS	2024-06-14 17:04:05.372253	TEST	f	\N	\N	\N	\N	\N	\N	\N
73	ACME	\N	\N	\N	ACE000000x00	\N	\N	\N	\N	\N	t	\N	2024-05-13 11:13:22.915	SYS	\N	\N	f	\N	\N	\N	\N	\N	\N	\N
74	Universidad del Estado	\N	\N	\N	UES000000XX0	\N	\N	\N	\N	\N	t	\N	2024-05-13 16:00:25.389	SYS	\N	\N	f	\N	\N	\N	\N	\N	\N	\N
77	ACMEC 	\N	\N	\N	ACM000000X01	\N	\N	\N	\N	\N	t	\N	2024-05-13 16:18:21.388	SYS	\N	\N	f	\N	\N	\N	\N	\N	\N	\N
79	La Escondida	\N	\N	\N	ESC010101X00	\N	\N	\N	\N	\N	t	\N	2024-05-23 10:23:06.536	SYS	\N	\N	f	\N	\N	\N	\N	\N	\N	\N
40	Juan Jose	Pérez	Pérez	PEPX000000XXX00	\N	H	juan.perez@gmail.com	\N	\N	\N	f	S	2024-05-27 14:43:21.285	test	2024-05-27 14:43:21.72115	Test	f	\N	\N	\N	\N	\N	\N	\N
82	Test	Test	Test	Test	\N	H	test@gmail.com	\N	\N	\N	f	S	2024-05-27 17:09:56.443	INFOR	\N	\N	f	\N	\N	\N	\N	\N	\N	\N
65	Oscar	Morales	Barranco	MOBX000000XXX00	\N	H	\N	222-222-2222	Domicilio Conocido S/N	\N	f	C	2024-06-03 16:32:34.977	SYS	2024-06-03 16:32:35.309676	Test	f	\N	\N	\N	\N	5	1	13131313131313131
69	Universidad de Puebla S.A.	\N	\N	\N	UPU000000X01	\N	\N	\N	Domicilio Conocido S/N	\N	t	\N	2024-06-03 16:36:57.19	SYS	2024-06-03 16:36:57.208578	Test	t	\N	\N	\N	\N	\N	\N	\N
81	José 	Cruz	López	CRLJ000000XXX01	\N	H	\N	\N	\N	\N	f	\N	2024-05-24 09:28:46.175	SYS	2024-06-14 17:04:05.374658	TEST	f	\N	\N	\N	\N	\N	\N	\N
85	Juana	Perez	Perez	PEPJ01010101MPMLRL01	\N	M	\N	222-532-5882	\N	\N	f	C	2024-06-03 17:23:41.61	SYS	\N	\N	f	\N	\N	\N	\N	1	4	1212121212121
72	Alfonso	Pérez	Pérez	PEPA000000ccc00	\N	H	alfonso.perez@gmail.com	6666666666	Domicilio Conocido S/N	\N	f	S	2024-06-03 17:27:22.992	SYS	2024-06-03 17:27:23.003326	Test	f	\N	\N	\N	\N	5	1	787878787878
66	Universidad de Puebla	\N	\N	\N	UPU000000X00	\N	contacto@upuebla.edu.mx	\N	Domicilio Conocido S/N	\N	t	\N	2024-06-03 17:35:24.331	SYS	2024-06-03 17:35:24.345592	Test	t	\N	\N	\N	\N	\N	\N	\N
89	Aceros S.A	\N	\N	\N	ACE900909X10	\N	\N	\N	\N	\N	t	\N	2024-06-04 11:31:31.209	SYS	\N	\N	f	\N	\N	\N	\N	\N	\N	\N
32	Alejandro	Ramírez	Cruz	RACA000000XXX00	\N	H	alejandro.ramirezc@gmail.com	\N	\N	\N	f	S	2024-05-27 17:14:30.149	test	2024-06-14 16:51:43.051922	Test	f	\N	\N	\N	\N	\N	\N	\N
61	Aceros S.A.			\N	ACE000101X97		aceros-sa@gmail.com	222-532-5882	11 SUR 111111		t	\N	2024-06-03 17:03:37.019	test	2024-06-14 16:52:13.890205	Test	t	85	\N	\N	\N	\N	\N	\N
70	José	Pérez	Pérez	PEPJ000000XXX01	\N	H	\N	\N	\N	\N	f	\N	2024-05-13 10:38:09.975	SYS	2024-06-14 17:03:50.985582	TEST	f	\N	\N	\N	\N	\N	\N	\N
71	María	López	López	LOLM000000XXX01	\N	M	\N	\N	\N	\N	f	\N	2024-05-13 10:38:09.975	SYS	2024-06-14 17:04:05.357793	TEST	f	\N	\N	\N	\N	\N	\N	\N
75	Alejandro	Sarmiento	López	SALA000000XXX00	\N	H	\N	\N	\N	\N	f	\N	2024-05-13 16:00:25.389	SYS	2024-06-14 17:04:05.364295	TEST	f	\N	\N	\N	\N	\N	\N	\N
76	Mario	Mario	Cruz	MAMC000000XXX01	\N	H	\N	\N	\N	\N	f	\N	2024-05-13 16:18:21.388	SYS	2024-06-14 17:04:05.36689	TEST	f	\N	\N	\N	\N	\N	\N	\N
78	Enrique	Pérez	Pérez	PEPX010101XXX00	\N	H	\N	\N	\N	\N	f	\N	2024-05-23 10:23:06.536	SYS	2024-06-14 17:04:05.369362	TEST	f	\N	\N	\N	\N	\N	\N	\N
83	TEST	TEST	TEST	TETT010101HPLMRL19	\N	M	\N	\N	\N	\N	f	\N	2024-05-28 18:08:29.267	SYS	2024-06-14 17:04:05.376956	TEST	f	\N	\N	\N	\N	\N	\N	\N
84	TEST	TEST	TEST	\N	TES010101A01		\N	\N	\N	\N	t	\N	2024-05-28 18:08:29.27	SYS	2024-06-14 17:04:05.379832	TEST	f	\N	\N	\N	\N	\N	\N	\N
86	José	Pérez 	Pérez 	PEPP000101HPLMRL10	\N	H	\N	\N	\N	\N	f	\N	2024-06-04 09:42:18.142	SYS	2024-06-14 17:04:05.38341	TEST	f	\N	\N	\N	\N	\N	\N	\N
88	José	Pérez 	Pérez 	PEPJ800101HPLMRL01	\N	H	\N	\N	\N	\N	f	\N	2024-06-04 11:31:31.208	SYS	2024-06-14 17:04:05.385656	TEST	f	\N	\N	\N	\N	\N	\N	\N
90	José	Pérez	Pérez	PEPJ800101HPLMRL07	\N	H	\N	\N	\N	\N	f	\N	2024-06-05 17:48:49.575	SYS	2024-06-14 17:04:05.389061	TEST	f	\N	\N	\N	\N	\N	\N	\N
91	Rosa María	Morales	Cisneros	\N		M	\N	\N	\N	\N	f	\N	2024-06-05 17:48:49.578	SYS	2024-06-14 17:04:05.392698	TEST	f	\N	\N	\N	\N	\N	\N	\N
87	Aceros S.A.	\N	\N	\N	ACE000000x10	\N	\N	\N	\N	\N	t	\N	2024-06-04 09:42:18.143	SYS	2024-06-14 17:12:24.653292	TEST	f	85	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: rol; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.rol (id, clave, descripcion, activo) FROM stdin;
1	ADMIN	Administrador	t
\.


--
-- Data for Name: rol_modulo_permiso; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.rol_modulo_permiso (rol_id, permiso_id, modulo_id, estatus) FROM stdin;
1	2	2	1
\.


--
-- Data for Name: rol_usuario; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.rol_usuario (usuario_id, rol_id, estatus, fecha_creacion, usuario_creo, fecha_actualizacion, usuario_actualizo) FROM stdin;
1	1	1	2024-05-03 16:08:08.752957	Test	2024-05-03 16:08:08.752957	\N
7	1	1	2024-05-15 13:03:06.968829	Test	2024-05-15 13:03:06.968829	\N
4	1	1	2024-05-14 13:40:00	Test	\N	\N
\.


--
-- Data for Name: sede; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.sede (id, clave, nombre, estatus, direccion, cp, municipio_id) FROM stdin;
3	CJXXI	Ciudad Judicial Siglo XXI	1	Periférico Ecológico Arco Sur Núm. 4000 	72810	2
\.


--
-- Data for Name: tipo_identificacion; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.tipo_identificacion (id, clave, descripcion, activo) FROM stdin;
1	INE	Credencial de Elector	t
2	PAS	Pasaporte	t
3	LCC	Licencia de Conductor	t
4	CDP	Cedula Profesional	t
5	CCV	Constancia de Vecindad	t
\.


--
-- Data for Name: tipo_juzgado; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.tipo_juzgado (id, clave, descripcion, activo) FROM stdin;
\.


--
-- Data for Name: usuario; Type: TABLE DATA; Schema: core; Owner: pjpuebla
--

COPY core.usuario (id, clave, correo_institucional, passwd, estatus, fecha_creacion, usuario_creo, fecha_actualizacion, usuario_actualizacion, persona_id, last_login) FROM stdin;
1	alejandro.ramirez	alejandro.ramirez@gmail.com	f6cf7f88816a2ec9b06d512d87224c0a7e04f4bc9b0acefbe837af735b4c78e9	0	2024-04-23 16:20:47.970696	test	\N	\N	32	\N
4	alejandro.ramirez01	alejandro.ramirez@pjpuebla.gob.mx	54fae415d50279507c738c271ef0d918c7905351b3bbdaf9ce39b3ea4bee6f96	0	2024-04-25 18:10:55.529	TEST	\N	\N	32	2024-04-29 11:12:10.068
7	usuario01	usuario01@pjpuebla.gob.mx	$2a$10$Kt3vtWR7IELeswUccSyk/OB/VwhZWF/v1xI2M3eibX4f6xgeFSuLG	0	2024-04-29 15:24:37.401	TEST	\N	\N	32	2024-06-14 12:35:33.959
8	demo	demo@pjpuebla.gob.mx	$2a$10$uo3N8rK.28hOvwiuFer8dO2LV/nNag./dPM3s6DZ1F/pvxW.x.0q6	1	2024-06-18 12:25:11.317	TEST	\N	\N	82	\N
\.


--
-- Data for Name: acuerdo; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.acuerdo (id, expediente_id, fecha_firma, aprobado, no_mediable, fecha_envio_juridico, fecha_vobo, estatus, fecha_creacion, usuario_creo, fecha_actualizacion, usuario_actualizo) FROM stdin;
\.


--
-- Data for Name: asesoria; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.asesoria (id, fecha, usuario_creo, persona_atendida_id, materia_id) FROM stdin;
\.


--
-- Data for Name: asistencia; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.asistencia (solicitud_id, sesion_mediacion_id, fecha_asistencia, asiste_usuario, asiste_invitado, tipo, acepta_usuario, acepta_invitado, fecha_registro, usuario_creo, fecha_actualizacion, usuario_actualizo, id) FROM stdin;
\.


--
-- Data for Name: config_citas; Type: TABLE DATA; Schema: mediacion; Owner: postgres
--

COPY mediacion.config_citas (id, clave, descripcion, valor, activo) FROM stdin;
3	DI	Días Inhábiles	S,D	t
4	H	Horario	08:00,14:00	t
1	DH	Días Habiles	1,2,3,4,5	t
\.


--
-- Data for Name: det_config_citas; Type: TABLE DATA; Schema: mediacion; Owner: postgres
--

COPY mediacion.det_config_citas (id, clave, descripcion, valor, activo, config_id, fecha_inicio, fecha_fin) FROM stdin;
4	VAC1	Primer Periodo Vacacional	\N	t	3	2024-07-15 00:00:00	2024-07-31 00:00:00
8	CITA2	Cita 2	10:00	t	4	2024-01-01 00:00:00	\N
9	CITA3	Cita 3	12:00	t	4	2024-01-01 00:00:00	\N
10	CITA4	Cita 4	13:30	t	4	2024-01-01 00:00:00	\N
7	CITA1	Cita 1	08:30	t	4	2024-01-01 00:00:00	\N
3	DP	Día del Padre	\N	t	3	2024-06-26 00:00:00	2024-06-26 00:00:00
\.


--
-- Data for Name: detalle_usuario_solicitud; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.detalle_usuario_solicitud (solicitud_id, tipo_identificacion_id, persona_id, numero_identificacion, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: expediente; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.expediente (id, folio, fecha_registro, mediador_id, solicitud_id, es_mediable, hay_acuerdo, asistencia_psicologica, asistencia_juridica, estatus) FROM stdin;
\.


--
-- Data for Name: fase_mediacion; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.fase_mediacion (id, secuencia, clave, descripcion, activo) FROM stdin;
1	1	AP	Apertura	t
\.


--
-- Data for Name: formato_fase; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.formato_fase (fase_id, formato_id, activo, opcional) FROM stdin;
1	1	t	f
1	3	t	t
1	2	t	t
1	6	t	t
1	4	t	t
1	5	t	t
\.


--
-- Data for Name: mediador; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.mediador (id, usuario_id, numero, certificado, estatus, supervisado_por, fecha_registro, usuario_registro, "fecha_actualización", usuario_actualizo) FROM stdin;
2	40	1	99999999	1	\N	2024-06-24 12:57:58.520677	test	\N	\N
3	76	2	99999998	1	\N	2024-06-24 12:59:06.999756	test	\N	\N
4	80	9999	\N	1	2	2024-06-24 13:00:24.795863	test	\N	\N
5	78	3	99999997	1	\N	2024-06-24 13:02:11.194063	test	\N	\N
\.


--
-- Data for Name: revision_acuerdo; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.revision_acuerdo (acuerdo_id, usuario_id_revisor, fecha_asignacion, fecha_revision, archivo_id, estatus, observaciones) FROM stdin;
\.


--
-- Data for Name: sesion_mediacion; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.sesion_mediacion (id, expediente_id, numero, fecha_sesion, observaciones, fecha_creacion, usuario_creo, fecha_actualizacion, usuario_actualizo) FROM stdin;
\.


--
-- Data for Name: solicitud; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.solicitud (id, folio, fecha_solicitud, usuario_persona_id, invitado_persona_id, fecha_sesion, es_mediable, canalizado, descripcion_conflicto, materia_id, asesoria_id, tipo_apertura_id, tipo_cierre_id, fecha_creacion, usuario_creo, fecha_actualizacion, usuario_actualizo, estatus) FROM stdin;
3	CJA-0001-2024	2024-05-06	40	61	\N	f	f	TEST	3	\N	1	\N	2024-05-06 15:39:30.97474	TEST	\N	\N	0
4	CJA-0008-2024	2024-05-06	40	61	\N	f	f	TEST	3	\N	2	\N	2024-05-07 12:34:55.885	TEST	\N	\N	0
9	CJA-0013-2024	2024-05-13	70	71	\N	f	f	REGISTRO DE PRUEBA	1	\N	2	\N	2024-05-13 10:38:09.971	TEST	\N	\N	0
10	CJA-0014-2024	2024-05-13	72	73	\N	f	f	jhjshlgjsfhgjhf	3	\N	1	\N	2024-05-13 11:13:22.914	TEST	\N	\N	0
11	CJA-0015-2024	2024-05-13	74	75	\N	f	f	CONFLICTO DE EJEMPLO	1	\N	1	\N	2024-05-13 16:00:25.387	TEST	\N	\N	0
12	CJA-0016-2024	2024-05-13	76	77	\N	f	f	TEXTO DE EJEMPLO	2	\N	2	\N	2024-05-13 16:18:21.387	TEST	\N	\N	0
13	CJA-0017-2024	2024-05-23	78	79	\N	f	f	SOLICITUD DE MEDIACIÓN DE PRUEBA	2	\N	1	\N	2024-05-23 10:23:06.535	TEST	\N	\N	0
14	CJA-0018-2024	2024-05-24	80	81	\N	f	f	Solicitud de ejemplo	1	\N	1	\N	2024-05-24 09:28:46.174	TEST	\N	\N	0
17	CJA-0021-2024	2024-05-06	40	61	\N	f	f	TEST	3	\N	2	\N	2024-05-28 18:02:31.659	TEST	\N	\N	0
52	CJA-0056-2024	2024-06-04	86	87	\N	f	f	test 	2	\N	1	\N	2024-06-04 09:42:18.141	TEST	\N	\N	0
53	CJA-0057-2024	2024-06-04	88	89	2024-06-25 08:30:00	f	f	dsjhvfdjshzjvhgsjghsfl\njdshfljsdhgfjsdhfjdslhfljsdhg\njshdgasjhgjashgjshgjshg	1	\N	1	\N	2024-06-04 11:31:31.207	TEST	\N	\N	0
54	CJA-0058-2024	2024-06-04	86	87	2024-06-25 10:00:00	t	f	test 	2	\N	1	\N	2024-06-04 12:48:39.155	TEST	\N	\N	1
55	CJA-0059-2024	2024-05-13	76	77	2024-06-25 12:00:00	t	f	TEXTO DE EJEMPLO	2	\N	2	\N	2024-06-05 12:09:22.387	TEST	\N	\N	0
56	CJA-0060-2024	2024-06-05	90	71	2024-06-25 13:30:00	t	f	wdjhfjagjhgshgsf\nf}gfghfdhdghdfhdfghgh\ngfhfdhfdhdhdh\nsgfhfdhfdhdh	2	\N	1	\N	2024-06-05 17:48:49.557	TEST	\N	\N	0
18	CJA-0022-2024	2024-05-28	83	84	2024-06-28 12:30:00	f	f	?????????????????????????	1	\N	2	\N	2024-05-28 18:08:29.257	TEST	\N	\N	0
19	CJA-0023-2024	2024-06-03	71	75	2024-06-27 08:30:00	f	f	test	3	\N	2	\N	2024-06-03 18:00:03.134	TEST	\N	\N	0
\.


--
-- Data for Name: solicitud_archivo; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.solicitud_archivo (solicitud_id, formato_id, archivo_id, estatus, fecha_creacion, usuario_creo, fecha_actualizacion, usuario_actualizo, id, persona_firma) FROM stdin;
56	2	\N	1	2024-06-14 18:01:43.616658	test	\N	\N	ad9dcc45-0272-4c09-9891-38654a9f3532	\N
54	2	2	1	2024-06-14 11:53:57.325372	test	\N	\N	d2d7735a-fd1f-4cee-8adb-d55a2cc0468c	Rosa María 
\.


--
-- Data for Name: solicitud_electonica; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.solicitud_electonica (solicitud_id, url, fecha_creacion, num_sesion) FROM stdin;
\.


--
-- Data for Name: solicitud_juzgado; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.solicitud_juzgado (solicitud_id, juzgado_id, persona_id_turno, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: tipo_apertura; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.tipo_apertura (id, clave, descripcion, activo) FROM stdin;
1	P	Presencial	t
2	L	En línea	t
\.


--
-- Data for Name: tipo_cierre; Type: TABLE DATA; Schema: mediacion; Owner: pjpuebla
--

COPY mediacion.tipo_cierre (id, clave, descripcion, activo) FROM stdin;
1	NM	No mediable	t
2	C	Canalizada	t
3	A	Acuerdo	t
4	NA	No acuerdo	t
5	IN	Inasistencia	t
\.


--
-- Name: archivo_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.archivo_id_seq', 2, true);


--
-- Name: area_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.area_id_seq', 5, true);


--
-- Name: clasificacion_persona_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.clasificacion_persona_id_seq', 1, false);


--
-- Name: estado_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.estado_id_seq', 1, true);


--
-- Name: formato_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.formato_id_seq', 20, true);


--
-- Name: instituciones_id_seq; Type: SEQUENCE SET; Schema: core; Owner: postgres
--

SELECT pg_catalog.setval('core.instituciones_id_seq', 5, true);


--
-- Name: juzgado_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.juzgado_id_seq', 1, false);


--
-- Name: materia_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.materia_id_seq', 6, true);


--
-- Name: modulo_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.modulo_id_seq', 2, true);


--
-- Name: municipio_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.municipio_id_seq', 2, true);


--
-- Name: permiso_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.permiso_id_seq', 2, true);


--
-- Name: persona_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.persona_id_seq', 92, true);


--
-- Name: rol_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.rol_id_seq', 1, true);


--
-- Name: sede_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.sede_id_seq', 3, true);


--
-- Name: tipo_identificacion_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.tipo_identificacion_id_seq', 5, true);


--
-- Name: tipo_juzgado_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.tipo_juzgado_id_seq', 1, false);


--
-- Name: usuario_id_seq; Type: SEQUENCE SET; Schema: core; Owner: pjpuebla
--

SELECT pg_catalog.setval('core.usuario_id_seq', 8, true);


--
-- Name: acuerdo_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: pjpuebla
--

SELECT pg_catalog.setval('mediacion.acuerdo_id_seq', 1, false);


--
-- Name: asesoria_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: pjpuebla
--

SELECT pg_catalog.setval('mediacion.asesoria_id_seq', 1, false);


--
-- Name: asistencia_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: pjpuebla
--

SELECT pg_catalog.setval('mediacion.asistencia_id_seq', 1, false);


--
-- Name: config_citas_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: postgres
--

SELECT pg_catalog.setval('mediacion.config_citas_id_seq', 4, true);


--
-- Name: det_config_citas_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: postgres
--

SELECT pg_catalog.setval('mediacion.det_config_citas_id_seq', 10, true);


--
-- Name: expediente_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: pjpuebla
--

SELECT pg_catalog.setval('mediacion.expediente_id_seq', 1, false);


--
-- Name: fase_mediacion_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: pjpuebla
--

SELECT pg_catalog.setval('mediacion.fase_mediacion_id_seq', 1, true);


--
-- Name: mediador_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: pjpuebla
--

SELECT pg_catalog.setval('mediacion.mediador_id_seq', 5, true);


--
-- Name: seq_foliador; Type: SEQUENCE SET; Schema: mediacion; Owner: postgres
--

SELECT pg_catalog.setval('mediacion.seq_foliador', 60, true);


--
-- Name: sesion_mediacion_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: pjpuebla
--

SELECT pg_catalog.setval('mediacion.sesion_mediacion_id_seq', 1, false);


--
-- Name: solicitud_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: pjpuebla
--

SELECT pg_catalog.setval('mediacion.solicitud_id_seq', 56, true);


--
-- Name: tipo_apertura_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: pjpuebla
--

SELECT pg_catalog.setval('mediacion.tipo_apertura_id_seq', 2, true);


--
-- Name: tipo_cierre_id_seq; Type: SEQUENCE SET; Schema: mediacion; Owner: pjpuebla
--

SELECT pg_catalog.setval('mediacion.tipo_cierre_id_seq', 5, true);


--
-- Name: archivo archivo_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.archivo
    ADD CONSTRAINT archivo_pkey PRIMARY KEY (id);


--
-- Name: area area_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.area
    ADD CONSTRAINT area_clave_key UNIQUE (clave);


--
-- Name: area area_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.area
    ADD CONSTRAINT area_pkey PRIMARY KEY (id);


--
-- Name: clasificacion_persona clasificacion_persona_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.clasificacion_persona
    ADD CONSTRAINT clasificacion_persona_clave_key UNIQUE (clave);


--
-- Name: clasificacion_persona clasificacion_persona_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.clasificacion_persona
    ADD CONSTRAINT clasificacion_persona_pkey PRIMARY KEY (id);


--
-- Name: formato clave_version_unique; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.formato
    ADD CONSTRAINT clave_version_unique UNIQUE (clave, version);


--
-- Name: detalle_persona detalle_persona_pk; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.detalle_persona
    ADD CONSTRAINT detalle_persona_pk PRIMARY KEY (persona_id, clasificacion_id);


--
-- Name: estado estado_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.estado
    ADD CONSTRAINT estado_clave_key UNIQUE (clave);


--
-- Name: estado estado_num_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.estado
    ADD CONSTRAINT estado_num_key UNIQUE (num);


--
-- Name: estado estado_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.estado
    ADD CONSTRAINT estado_pkey PRIMARY KEY (id);


--
-- Name: formato formato_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.formato
    ADD CONSTRAINT formato_pkey PRIMARY KEY (id);


--
-- Name: instituciones instituciones_pk; Type: CONSTRAINT; Schema: core; Owner: postgres
--

ALTER TABLE ONLY core.instituciones
    ADD CONSTRAINT instituciones_pk PRIMARY KEY (id);


--
-- Name: instituciones instituciones_unique; Type: CONSTRAINT; Schema: core; Owner: postgres
--

ALTER TABLE ONLY core.instituciones
    ADD CONSTRAINT instituciones_unique UNIQUE (clave);


--
-- Name: juzgado juzgado_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.juzgado
    ADD CONSTRAINT juzgado_clave_key UNIQUE (clave);


--
-- Name: juzgado juzgado_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.juzgado
    ADD CONSTRAINT juzgado_pkey PRIMARY KEY (id);


--
-- Name: materia materia_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.materia
    ADD CONSTRAINT materia_clave_key UNIQUE (clave);


--
-- Name: materia materia_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.materia
    ADD CONSTRAINT materia_pkey PRIMARY KEY (id);


--
-- Name: modulo modulo_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.modulo
    ADD CONSTRAINT modulo_clave_key UNIQUE (clave);


--
-- Name: modulo modulo_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.modulo
    ADD CONSTRAINT modulo_pkey PRIMARY KEY (id);


--
-- Name: municipio municipio_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.municipio
    ADD CONSTRAINT municipio_clave_key UNIQUE (clave);


--
-- Name: municipio municipio_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.municipio
    ADD CONSTRAINT municipio_pkey PRIMARY KEY (id);


--
-- Name: permiso permiso_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.permiso
    ADD CONSTRAINT permiso_clave_key UNIQUE (clave);


--
-- Name: permiso permiso_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.permiso
    ADD CONSTRAINT permiso_pkey PRIMARY KEY (id);


--
-- Name: persona persona_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.persona
    ADD CONSTRAINT persona_pkey PRIMARY KEY (id);


--
-- Name: persona persona_unique; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.persona
    ADD CONSTRAINT persona_unique UNIQUE (nombre, apellido_paterno, apellido_materno, curp, rfc, email);


--
-- Name: rol rol_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.rol
    ADD CONSTRAINT rol_clave_key UNIQUE (clave);


--
-- Name: rol_modulo_permiso rol_modulo_permiso_pk; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.rol_modulo_permiso
    ADD CONSTRAINT rol_modulo_permiso_pk PRIMARY KEY (rol_id, permiso_id, modulo_id);


--
-- Name: rol rol_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.rol
    ADD CONSTRAINT rol_pkey PRIMARY KEY (id);


--
-- Name: rol_usuario rol_usuario_pk; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.rol_usuario
    ADD CONSTRAINT rol_usuario_pk PRIMARY KEY (usuario_id, rol_id);


--
-- Name: sede sede_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.sede
    ADD CONSTRAINT sede_clave_key UNIQUE (clave);


--
-- Name: sede sede_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.sede
    ADD CONSTRAINT sede_pkey PRIMARY KEY (id);


--
-- Name: tipo_identificacion tipo_identificacion_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.tipo_identificacion
    ADD CONSTRAINT tipo_identificacion_pkey PRIMARY KEY (id);


--
-- Name: tipo_juzgado tipo_juzgado_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.tipo_juzgado
    ADD CONSTRAINT tipo_juzgado_clave_key UNIQUE (clave);


--
-- Name: tipo_juzgado tipo_juzgado_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.tipo_juzgado
    ADD CONSTRAINT tipo_juzgado_pkey PRIMARY KEY (id);


--
-- Name: usuario usuario_clave_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.usuario
    ADD CONSTRAINT usuario_clave_key UNIQUE (clave);


--
-- Name: usuario usuario_correo_institucional_key; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.usuario
    ADD CONSTRAINT usuario_correo_institucional_key UNIQUE (correo_institucional);


--
-- Name: usuario usuario_pkey; Type: CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);


--
-- Name: acuerdo acuerdo_pkey; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.acuerdo
    ADD CONSTRAINT acuerdo_pkey PRIMARY KEY (id);


--
-- Name: asesoria asesoria_pkey; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.asesoria
    ADD CONSTRAINT asesoria_pkey PRIMARY KEY (id);


--
-- Name: asistencia asistencia_pk; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.asistencia
    ADD CONSTRAINT asistencia_pk PRIMARY KEY (id);


--
-- Name: config_citas config_citas_pk; Type: CONSTRAINT; Schema: mediacion; Owner: postgres
--

ALTER TABLE ONLY mediacion.config_citas
    ADD CONSTRAINT config_citas_pk PRIMARY KEY (id);


--
-- Name: config_citas config_citas_unique; Type: CONSTRAINT; Schema: mediacion; Owner: postgres
--

ALTER TABLE ONLY mediacion.config_citas
    ADD CONSTRAINT config_citas_unique UNIQUE (clave);


--
-- Name: det_config_citas det_config_citas_pk; Type: CONSTRAINT; Schema: mediacion; Owner: postgres
--

ALTER TABLE ONLY mediacion.det_config_citas
    ADD CONSTRAINT det_config_citas_pk PRIMARY KEY (id);


--
-- Name: detalle_usuario_solicitud detalle_usuario_solicitud_pk; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.detalle_usuario_solicitud
    ADD CONSTRAINT detalle_usuario_solicitud_pk PRIMARY KEY (solicitud_id, tipo_identificacion_id, persona_id);


--
-- Name: expediente expediente_folio_key; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.expediente
    ADD CONSTRAINT expediente_folio_key UNIQUE (folio);


--
-- Name: expediente expediente_pkey; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.expediente
    ADD CONSTRAINT expediente_pkey PRIMARY KEY (id);


--
-- Name: fase_mediacion fase_mediacion_pkey; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.fase_mediacion
    ADD CONSTRAINT fase_mediacion_pkey PRIMARY KEY (id);


--
-- Name: formato_fase formato_fase_pk; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.formato_fase
    ADD CONSTRAINT formato_fase_pk PRIMARY KEY (fase_id, formato_id);


--
-- Name: mediador mediador_pkey; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.mediador
    ADD CONSTRAINT mediador_pkey PRIMARY KEY (id);


--
-- Name: mediador mediador_unique; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.mediador
    ADD CONSTRAINT mediador_unique UNIQUE (certificado);


--
-- Name: revision_acuerdo revision_acuerdo_pk; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.revision_acuerdo
    ADD CONSTRAINT revision_acuerdo_pk PRIMARY KEY (acuerdo_id, usuario_id_revisor, archivo_id);


--
-- Name: sesion_mediacion sesion_mediacion_pkey; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.sesion_mediacion
    ADD CONSTRAINT sesion_mediacion_pkey PRIMARY KEY (id);


--
-- Name: solicitud_archivo solicitud_archivo_pk; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud_archivo
    ADD CONSTRAINT solicitud_archivo_pk PRIMARY KEY (id);


--
-- Name: solicitud_electonica solicitud_electonica_pk; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud_electonica
    ADD CONSTRAINT solicitud_electonica_pk PRIMARY KEY (solicitud_id, num_sesion);


--
-- Name: solicitud solicitud_folio_key; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud
    ADD CONSTRAINT solicitud_folio_key UNIQUE (folio);


--
-- Name: solicitud_juzgado solicitud_juzgado_pk; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud_juzgado
    ADD CONSTRAINT solicitud_juzgado_pk PRIMARY KEY (solicitud_id, juzgado_id);


--
-- Name: solicitud solicitud_pkey; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud
    ADD CONSTRAINT solicitud_pkey PRIMARY KEY (id);


--
-- Name: tipo_apertura tipo_apertura_clave_key; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.tipo_apertura
    ADD CONSTRAINT tipo_apertura_clave_key UNIQUE (clave);


--
-- Name: tipo_apertura tipo_apertura_pkey; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.tipo_apertura
    ADD CONSTRAINT tipo_apertura_pkey PRIMARY KEY (id);


--
-- Name: tipo_cierre tipo_cierre_clave_key; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.tipo_cierre
    ADD CONSTRAINT tipo_cierre_clave_key UNIQUE (clave);


--
-- Name: tipo_cierre tipo_cierre_pkey; Type: CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.tipo_cierre
    ADD CONSTRAINT tipo_cierre_pkey PRIMARY KEY (id);


--
-- Name: persona persona_valid; Type: TRIGGER; Schema: core; Owner: pjpuebla
--

CREATE TRIGGER persona_valid BEFORE INSERT OR UPDATE ON core.persona FOR EACH ROW EXECUTE FUNCTION core.persona_valid();


--
-- Name: area area_area_padre_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.area
    ADD CONSTRAINT area_area_padre_fkey FOREIGN KEY (area_padre) REFERENCES core.area(id);


--
-- Name: area area_responsable_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.area
    ADD CONSTRAINT area_responsable_fkey FOREIGN KEY (responsable) REFERENCES core.persona(id);


--
-- Name: area area_sede_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.area
    ADD CONSTRAINT area_sede_id_fkey FOREIGN KEY (sede_id) REFERENCES core.sede(id);


--
-- Name: detalle_persona detalle_persona_clasificacion_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.detalle_persona
    ADD CONSTRAINT detalle_persona_clasificacion_id_fkey FOREIGN KEY (clasificacion_id) REFERENCES core.clasificacion_persona(id);


--
-- Name: detalle_persona detalle_persona_persona_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.detalle_persona
    ADD CONSTRAINT detalle_persona_persona_id_fkey FOREIGN KEY (persona_id) REFERENCES core.persona(id);


--
-- Name: juzgado juzgado_materia_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.juzgado
    ADD CONSTRAINT juzgado_materia_id_fkey FOREIGN KEY (materia_id) REFERENCES core.materia(id);


--
-- Name: juzgado juzgado_sede_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.juzgado
    ADD CONSTRAINT juzgado_sede_id_fkey FOREIGN KEY (sede_id) REFERENCES core.sede(id);


--
-- Name: juzgado juzgado_tipo_juzgado_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.juzgado
    ADD CONSTRAINT juzgado_tipo_juzgado_fkey FOREIGN KEY (tipo_juzgado) REFERENCES core.tipo_juzgado(id);


--
-- Name: modulo modulo_modulo_padre_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.modulo
    ADD CONSTRAINT modulo_modulo_padre_fkey FOREIGN KEY (modulo_padre) REFERENCES core.modulo(id);


--
-- Name: municipio municipio_estado_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.municipio
    ADD CONSTRAINT municipio_estado_id_fkey FOREIGN KEY (estado_id) REFERENCES core.estado(id);


--
-- Name: persona persona_persona_fk; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.persona
    ADD CONSTRAINT persona_persona_fk FOREIGN KEY (representante) REFERENCES core.persona(id);


--
-- Name: rol_modulo_permiso rol_modulo_permiso_modulo_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.rol_modulo_permiso
    ADD CONSTRAINT rol_modulo_permiso_modulo_id_fkey FOREIGN KEY (modulo_id) REFERENCES core.modulo(id);


--
-- Name: rol_modulo_permiso rol_modulo_permiso_permiso_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.rol_modulo_permiso
    ADD CONSTRAINT rol_modulo_permiso_permiso_id_fkey FOREIGN KEY (permiso_id) REFERENCES core.permiso(id);


--
-- Name: rol_modulo_permiso rol_modulo_permiso_rol_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.rol_modulo_permiso
    ADD CONSTRAINT rol_modulo_permiso_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES core.rol(id);


--
-- Name: rol_usuario rol_usuario_rol_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.rol_usuario
    ADD CONSTRAINT rol_usuario_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES core.rol(id);


--
-- Name: rol_usuario rol_usuario_usuario_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.rol_usuario
    ADD CONSTRAINT rol_usuario_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES core.usuario(id);


--
-- Name: sede sede_municipio_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.sede
    ADD CONSTRAINT sede_municipio_id_fkey FOREIGN KEY (municipio_id) REFERENCES core.municipio(id);


--
-- Name: usuario usuario_persona_id_fkey; Type: FK CONSTRAINT; Schema: core; Owner: pjpuebla
--

ALTER TABLE ONLY core.usuario
    ADD CONSTRAINT usuario_persona_id_fkey FOREIGN KEY (persona_id) REFERENCES core.persona(id);


--
-- Name: acuerdo acuerdo_expediente_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.acuerdo
    ADD CONSTRAINT acuerdo_expediente_id_fkey FOREIGN KEY (expediente_id) REFERENCES mediacion.expediente(id);


--
-- Name: asistencia asistencia_sesion_mediacion_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.asistencia
    ADD CONSTRAINT asistencia_sesion_mediacion_id_fkey FOREIGN KEY (sesion_mediacion_id) REFERENCES mediacion.sesion_mediacion(id);


--
-- Name: asistencia asistencia_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.asistencia
    ADD CONSTRAINT asistencia_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud(id);


--
-- Name: detalle_usuario_solicitud detalle_usuario_solicitud_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.detalle_usuario_solicitud
    ADD CONSTRAINT detalle_usuario_solicitud_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud(id);


--
-- Name: detalle_usuario_solicitud detalle_usuario_solicitud_tipo_identificacion_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.detalle_usuario_solicitud
    ADD CONSTRAINT detalle_usuario_solicitud_tipo_identificacion_id_fkey FOREIGN KEY (tipo_identificacion_id) REFERENCES core.tipo_identificacion(id);


--
-- Name: expediente expediente_mediador_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.expediente
    ADD CONSTRAINT expediente_mediador_id_fkey FOREIGN KEY (mediador_id) REFERENCES mediacion.mediador(id);


--
-- Name: expediente expediente_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.expediente
    ADD CONSTRAINT expediente_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud(id);


--
-- Name: formato_fase formato_fase_fase_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.formato_fase
    ADD CONSTRAINT formato_fase_fase_id_fkey FOREIGN KEY (fase_id) REFERENCES mediacion.fase_mediacion(id);


--
-- Name: formato_fase formato_fase_formato_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.formato_fase
    ADD CONSTRAINT formato_fase_formato_id_fkey FOREIGN KEY (formato_id) REFERENCES core.formato(id);


--
-- Name: mediador mediador_supervisado_por_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.mediador
    ADD CONSTRAINT mediador_supervisado_por_fkey FOREIGN KEY (supervisado_por) REFERENCES mediacion.mediador(id);


--
-- Name: mediador mediador_usuario_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.mediador
    ADD CONSTRAINT mediador_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES core.persona(id);


--
-- Name: revision_acuerdo revision_acuerdo_acuerdo_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.revision_acuerdo
    ADD CONSTRAINT revision_acuerdo_acuerdo_id_fkey FOREIGN KEY (acuerdo_id) REFERENCES mediacion.acuerdo(id);


--
-- Name: sesion_mediacion sesion_mediacion_expediente_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.sesion_mediacion
    ADD CONSTRAINT sesion_mediacion_expediente_id_fkey FOREIGN KEY (expediente_id) REFERENCES mediacion.expediente(id);


--
-- Name: solicitud_archivo solicitud_archivo_archivo_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud_archivo
    ADD CONSTRAINT solicitud_archivo_archivo_id_fkey FOREIGN KEY (archivo_id) REFERENCES core.archivo(id);


--
-- Name: solicitud_archivo solicitud_archivo_formato_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud_archivo
    ADD CONSTRAINT solicitud_archivo_formato_id_fkey FOREIGN KEY (formato_id) REFERENCES core.formato(id);


--
-- Name: solicitud_archivo solicitud_archivo_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud_archivo
    ADD CONSTRAINT solicitud_archivo_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud(id);


--
-- Name: solicitud solicitud_asesoria_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud
    ADD CONSTRAINT solicitud_asesoria_id_fkey FOREIGN KEY (asesoria_id) REFERENCES mediacion.asesoria(id);


--
-- Name: solicitud_electonica solicitud_electonica_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud_electonica
    ADD CONSTRAINT solicitud_electonica_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud(id);


--
-- Name: solicitud solicitud_invitado_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud
    ADD CONSTRAINT solicitud_invitado_id_fkey FOREIGN KEY (invitado_persona_id) REFERENCES core.persona(id);


--
-- Name: solicitud_juzgado solicitud_juzgado_juzgado_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud_juzgado
    ADD CONSTRAINT solicitud_juzgado_juzgado_id_fkey FOREIGN KEY (juzgado_id) REFERENCES core.juzgado(id);


--
-- Name: solicitud_juzgado solicitud_juzgado_solicitud_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud_juzgado
    ADD CONSTRAINT solicitud_juzgado_solicitud_id_fkey FOREIGN KEY (solicitud_id) REFERENCES mediacion.solicitud(id);


--
-- Name: solicitud solicitud_materia_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud
    ADD CONSTRAINT solicitud_materia_id_fkey FOREIGN KEY (materia_id) REFERENCES core.materia(id);


--
-- Name: solicitud solicitud_tipo_apertura_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud
    ADD CONSTRAINT solicitud_tipo_apertura_id_fkey FOREIGN KEY (tipo_apertura_id) REFERENCES mediacion.tipo_apertura(id);


--
-- Name: solicitud solicitud_tipo_cierre_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud
    ADD CONSTRAINT solicitud_tipo_cierre_id_fkey FOREIGN KEY (tipo_cierre_id) REFERENCES mediacion.tipo_cierre(id);


--
-- Name: solicitud solicitud_usuario_id_fkey; Type: FK CONSTRAINT; Schema: mediacion; Owner: pjpuebla
--

ALTER TABLE ONLY mediacion.solicitud
    ADD CONSTRAINT solicitud_usuario_id_fkey FOREIGN KEY (usuario_persona_id) REFERENCES core.persona(id);


--
-- Name: FUNCTION nombre_persona(p_persona_id integer); Type: ACL; Schema: core; Owner: postgres
--

GRANT ALL ON FUNCTION core.nombre_persona(p_persona_id integer) TO pjpuebla;


--
-- Name: FUNCTION foliador(clave_area character varying); Type: ACL; Schema: mediacion; Owner: postgres
--

GRANT ALL ON FUNCTION mediacion.foliador(clave_area character varying) TO pjpuebla;


--
-- Name: TABLE qry_area_responsable; Type: ACL; Schema: core; Owner: postgres
--

GRANT SELECT ON TABLE core.qry_area_responsable TO pjpuebla;


--
-- Name: TABLE qry_solicitud; Type: ACL; Schema: mediacion; Owner: postgres
--

GRANT SELECT ON TABLE mediacion.qry_solicitud TO pjpuebla;


--
-- Name: SEQUENCE seq_foliador; Type: ACL; Schema: mediacion; Owner: postgres
--

GRANT USAGE ON SEQUENCE mediacion.seq_foliador TO pjpuebla;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: core; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA core GRANT ALL ON FUNCTIONS  TO pjpuebla;


--
-- PostgreSQL database dump complete
--

