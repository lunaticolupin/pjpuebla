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

    @GetMapping("/{id}")
    public ResponseEntity<GenericResponse> getSolicitudById(@PathVariable("id") Integer solicitudId) {

        Solicitud solicitud = solicitudes.findById(solicitudId);
        response = new GenericResponse();

        if (solicitud==null){
            String mensaje = String.format("La solicitud con ID %s no existe", solicitudId);

            response.setMessage(mensaje);
            return ResponseEntity.badRequest().body(response);
        }

        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(solicitud);

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

    @PostMapping("/save/{id}")
    public ResponseEntity<GenericResponse> guardar(@Valid @RequestBody Solicitud entidad, Errors errors) {
        response = new GenericResponse();

        // Determinamos si la persona es moral o física para obtener su CURP o RFC.
        String CurpOrRfc_invitado = entidad.getInvitadoPersona().getPersonaMoral() ?  entidad.getInvitadoPersona().getRfc() : entidad.getInvitadoPersona().getCurp();
        String CurpOrRfc_persona = entidad.getUsuarioPersona().getPersonaMoral() ?  entidad.getUsuarioPersona().getRfc() : entidad.getUsuarioPersona().getCurp();
    
        // Buscamos si ya existe el usuario invitado y el usuario persona en la base de datos.
        Persona usuario_invitado = personas.findByCurpOrRfc(CurpOrRfc_invitado);
        Persona usuario_persona = personas.findByCurpOrRfc(CurpOrRfc_persona);
    
        // Si el usuario invitado no existe, lo creamos y lo guardamos en la base de datos.
        if(usuario_invitado == null){
            usuario_invitado = personas.save(entidad.getInvitadoPersona());
            entidad.setInvitadoPersona(usuario_invitado); // Asignamos el usuario invitado recién creado a la entidad `Solicitud`.
        }
    
        // Si el usuario persona no existe, lo creamos y lo guardamos en la base de datos.
        if(usuario_persona == null){
            usuario_persona = personas.save(entidad.getUsuarioPersona());
            entidad.setUsuarioPersona(usuario_persona); // Asignamos el usuario persona recién creado a la entidad `Solicitud`.
        }
    
        // Asignamos los objetos `usuario_invitado` y `usuario_persona` a la entidad `Solicitud` 
        // para asegurar que las relaciones con las llaves foráneas estén correctamente establecidas.
        entidad.setInvitadoPersona(usuario_invitado);
        entidad.setUsuarioPersona(usuario_persona);
    
        // Si existen errores de validación en la entidad, los retornamos en la respuesta.
        if (errors.hasErrors()){
            response.setMessage("La entidad tiene errores");
            response.setErrors(errors.getAllErrors());
            return ResponseEntity.badRequest().body(response);
        }
    
        // Actualizamos la fecha de actualización y los usuarios que crearon y actualizaron la entidad.
        entidad.setFechaActualizacion(new Date());
        entidad.setUsuarioActualizo("TEST"); 
        entidad.setUsuarioCreo("TEST"); 
    
        // Guardamos o actualizamos la entidad `Solicitud` en la base de datos.
        Solicitud solicitudActualizada = solicitudes.save(entidad);
        
        // Construimos la respuesta con los datos de la solicitud actualizada.
        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(solicitudActualizada);
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/delete/{id}")
    public ResponseEntity<GenericResponse> eliminar(@PathVariable("id") Integer id) {
        //TODO: process POST request
        response = new GenericResponse();

        

        if (solicitudes.esEliminable(id)){
            response.setSuccess(solicitudes.delete(id));
            response.setMessage("Solicitud eliminada");
            return ResponseEntity.ok(response);
        }
        
        response.setMessage("La Solicitud no puede ser eliminada");

        return ResponseEntity.badRequest().body(response);
        
    }

    @PostMapping("/generarFecha/{id}")
    public ResponseEntity<GenericResponse> generarFechaSesion(@PathVariable("id") Integer solicitudId) {
        //TODO: process POST request
        GenericResponse response = new GenericResponse();
        Date fechaSesion = solicitudes.generarFechaSesion(solicitudId);

        if (fechaSesion!=null){
            response.setSuccess(true);
            response.setData(fechaSesion);

            return ResponseEntity.ok(response);
        }
        
        response.setMessage("No se pudo asignar fecha");
        return ResponseEntity.badRequest().body(response);
    }
    
    @PostMapping("/registrarDocumento/{id}")
    public ResponseEntity<GenericResponse> registrarDocumento(@PathVariable("id") Integer solicitudId, @RequestParam("claveFormato") String claveFormato) {
        GenericResponse response = new GenericResponse();
        boolean result=false;

        if (solicitudId!=null && !claveFormato.isEmpty()){
            String usuario = "TEST";
            String persona = "Rosa María Morales Cisneros";

            result = solicitudes.registrarDocumento(solicitudId, claveFormato, usuario, persona);
        }

        if (result){
            response.setMessage("Documento registrado");
        }

        response.setSuccess(result);
        
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
