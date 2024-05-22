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