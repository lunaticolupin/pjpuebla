package mx.pjpuebla.backend.core.controller;

import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.core.service.PersonaService;
import mx.pjpuebla.backend.response.GenericResponse;

import java.sql.SQLException;
import java.util.Date;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.Errors;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import jakarta.validation.Valid;


@RestController
@RequestMapping("personas")
@RequiredArgsConstructor
public class PersonaController {
    private final PersonaService personas;

    @GetMapping("")
    public ResponseEntity<GenericResponse> getPersonas() {
        GenericResponse response = new GenericResponse();
        
        response.setSuccess(true);
        response.setData(personas.findAll());
        
        return ResponseEntity.ok(response);
        
    }

    @GetMapping("/{id}")
    public ResponseEntity<GenericResponse> getPersona(@PathVariable("id") Integer id){
        GenericResponse response = new GenericResponse();
        Persona persona = personas.findById(id);

        if (persona==null){
            response.setMessage("La entidad no existe");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        response.setSuccess(true);
        response.setData(persona);

        return ResponseEntity.ok(response);

    }

    @PostMapping("/save")
    public ResponseEntity<GenericResponse> guardarPersona(@Valid @RequestBody Persona entity, Errors errors) {
        GenericResponse response = new GenericResponse();
        try{
            if (errors.hasErrors()){
                response.setMessage("Entidad no valida");
                response.setErrors(errors.getAllErrors());
                return ResponseEntity.internalServerError().body(response);
            }

            if (entity.getId() != null && personas.existsByID(entity.getId())){
                entity.setFechaActualizacion(new Date());
                entity.setUsuarioActualizo("Test");
            }
    
            Persona persona = personas.save(entity);
    
            if (persona==null){
                response.setMessage("No se pudo guardar la entidad");
                response.setData(entity);
                throw new SQLException(response.getMessage());
            }

            response.setSuccess(true);
            response.setMessage("OK");
            response.setData(persona);
            
            return ResponseEntity.ok(response);
        }catch (Exception e){
            e.printStackTrace();
            response.setMessage(e.getCause().getCause().getLocalizedMessage());

            return ResponseEntity.internalServerError().body(response);
        }
        
    }

    @PostMapping("/delete/{id}")
    public ResponseEntity<GenericResponse> borrarPersona(@PathVariable("id") Integer id) {
        Persona persona = personas.findById(id);
        GenericResponse response = new GenericResponse();

        if (persona==null){
            response.setMessage("El ID no existe");

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        try{
            boolean result = personas.delete(persona);

            if (result){
                String mensaje = String.format("La entidad con ID %d fue eliminada", id);
                response.setSuccess(result);
                response.setMessage(mensaje);
    
                return ResponseEntity.ok(response);
            }

            throw new SQLException("No se pudo eliminar el ID");
    
            
        }catch (Exception e){
            response.setMessage(e.getCause().getCause().getLocalizedMessage());
            return ResponseEntity.internalServerError().body(response);
        }
        
    }


}
