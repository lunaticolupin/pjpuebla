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

