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