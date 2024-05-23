ALTER TABLE mediacion.solicitud ADD estatus smallint DEFAULT 0 NULL;
ALTER TABLE mediacion.solicitud ALTER COLUMN fecha_sesion DROP NOT NULL;
ALTER TABLE mediacion.solicitud ALTER COLUMN asesoria_id DROP NOT NULL;
ALTER TABLE mediacion.solicitud ALTER COLUMN tipo_cierre_id DROP NOT NULL;



ALTER TABLE core.usuario ADD last_login timestamp NULL;

CREATE OR REPLACE FUNCTION mediacion.foliador(clave_area character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare folio varchar;
	BEGIN
		select clave_area || '-' || lpad(nextval('mediacion.seq_foliador')::text,4,'0')  ||  '-' || EXTRACT(YEAR FROM CURRENT_DATE) into folio;
	
		return folio;
	END;
$function$
;

create sequence mediacion.seq_foliador start with 1;

-- mediacion.qry_solicitud source

CREATE OR REPLACE VIEW mediacion.qry_solicitud
AS SELECT s.id,
    s.folio,
    s.fecha_solicitud,
    m.descripcion AS materia,
    p.nombre AS usuario_nombre,
    p.apellido_paterno AS usuario_apaterno,
    p.apellido_materno AS usuario_amaterno,
    p2.nombre AS invitado_nombre,
    p2.apellido_paterno AS invitado_apaterno,
    p2.apellido_materno AS invitado_amaterno,
    s.descripcion_conflicto
   FROM mediacion.solicitud s
     JOIN core.persona p ON p.id = s.usuario_persona_id
     JOIN core.persona p2 ON p2.id = s.invitado_persona_id
     JOIN core.materia m ON m.id = s.materia_id
     JOIN mediacion.tipo_apertura ta ON ta.id = s.tipo_apertura_id;
    
GRANT SELECT ON TABLE mediacion.qry_solicitud TO pjpuebla;

-- DROP FUNCTION core.nombre_persona(int4);
-- Funcion para devolver el nombre completo de una persona -- 
CREATE OR REPLACE FUNCTION core.nombre_persona(p_persona_id integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
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
$function$
;

-- mediacion.qry_solicitud source
-- Actualización de la Vista qry_solicitud, se incorpora la funcion nombre_persona
CREATE OR REPLACE VIEW mediacion.qry_solicitud
AS SELECT s.id,
    s.folio,
    s.fecha_solicitud,
    m.descripcion AS materia,
    p.nombre AS usuario_nombre,
    p.apellido_paterno AS usuario_apaterno,
    p.apellido_materno AS usuario_amaterno,
    p2.nombre AS invitado_nombre,
    p2.apellido_paterno AS invitado_apaterno,
    p2.apellido_materno AS invitado_amaterno,
    s.descripcion_conflicto,
    core.nombre_persona(p.id) AS usuario_nombre_completo,
    core.nombre_persona(p2.id) AS invitado_nombre_completo
   FROM mediacion.solicitud s
     JOIN core.persona p ON p.id = s.usuario_persona_id
     JOIN core.persona p2 ON p2.id = s.invitado_persona_id
     JOIN core.materia m ON m.id = s.materia_id
     JOIN mediacion.tipo_apertura ta ON ta.id = s.tipo_apertura_id;