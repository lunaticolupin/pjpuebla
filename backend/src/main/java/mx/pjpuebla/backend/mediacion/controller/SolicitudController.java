package mx.pjpuebla.backend.mediacion.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Materia;
import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.core.service.PersonaService;
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.entitiy.TipoApertura;
import mx.pjpuebla.backend.mediacion.service.SolicitudService;
import mx.pjpuebla.backend.response.GenericResponse;

import java.sql.SQLException;
import java.util.Date;
import java.util.List;

import org.hibernate.exception.DataException;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.Errors;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;




@RestController
@RequestMapping("mediacion/solicitud")
@RequiredArgsConstructor
public class SolicitudController {
    private final SolicitudService solicitudes;
    private final PersonaService personas;
    private GenericResponse response;

    @GetMapping("")
    public ResponseEntity<GenericResponse> listar() {
        response = new GenericResponse(true, "OK", null, null);

        List<Solicitud> lista = solicitudes.findAll();
        response.setData(lista);

        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/folio/{folio}")
    public ResponseEntity<GenericResponse> getSolicitud(@PathVariable("folio") String folio) {

        Solicitud solicitud = solicitudes.findByFolio(folio);
        response = new GenericResponse();

        if (solicitud==null){
            String mensaje = String.format("La solicitud con folio %s no existe", folio);

            response.setMessage(mensaje);
            return ResponseEntity.badRequest().body(response);
        }

        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(solicitud);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/add")
    public ResponseEntity<GenericResponse> agregar(@Valid @RequestBody Solicitud entidad, Errors errors) {
        response = new GenericResponse();

        if (errors.hasErrors()){
            response.setMessage("La entidad tiene errores");
            response.setErrors(errors.getAllErrors());

            return ResponseEntity.badRequest().body(response);
        }
        
        if (entidad.getId()!=null){
            response.setMessage("La entidad ya existe");

            return ResponseEntity.badRequest().body(response);
        }

        try{
            if (entidad.getUsuarioPersona().getId()==null){
                Persona usuarioPersona = personas.save(entidad.getUsuarioPersona());

                if (usuarioPersona==null){
                    throw new DataException("No se pudo registrar al Usuario", new SQLException());
                }

                entidad.setUsuarioPersona(usuarioPersona);
            
            }

            if (entidad.getInvitadoPersona().getId()==null){
                Persona invitadoPersona = personas.save(entidad.getInvitadoPersona());

                if (invitadoPersona==null){
                    throw new DataException("No se pudo registrar al Usuario", new SQLException());
                }

                entidad.setInvitadoPersona(invitadoPersona);
            }
        }catch(Exception e){
            response.setMessage("No se pudo registrar al Usuario o Invitado");
            response.setErrors(e.getMessage());

            return ResponseEntity.internalServerError().body(response);
        }

        entidad.setFolio(solicitudes.generarFolio("CJA"));
        entidad.setUsuarioCreo("TEST");

        Solicitud nueva = solicitudes.save(entidad);
        
        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(nueva);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/save")
    public ResponseEntity<GenericResponse> guardar(@Valid @RequestBody Solicitud entidad) {

        //entidad.setFolio(solicitudes.generarFolio("CJA"));
        //entidad.setUsuarioCreo("TEST");

        entidad.setFechaActualizacion(new Date());
        entidad.setUsuarioActualizo("TEST");
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("template")
    public ResponseEntity<GenericResponse> getJsonTemplate() {
        Solicitud template = new Solicitud();
        Persona persona = new Persona();
        TipoApertura tipoApertura = new TipoApertura();
        Materia materia = new Materia();

        template.setUsuarioPersona(persona);
        template.setInvitadoPersona(persona);
        template.setTipoApertura(tipoApertura);
        template.setMateria(materia);

        response = new GenericResponse(true, "OK", null, template);

        return ResponseEntity.ok(response);
    }
    
    
}
