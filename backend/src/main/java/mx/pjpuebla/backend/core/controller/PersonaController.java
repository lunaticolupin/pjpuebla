package mx.pjpuebla.backend.core.controller;

import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.core.service.PersonaService;

import java.util.Date;

import java.util.List;
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
    public ResponseEntity<List<Persona>> personas() {
        
        return ResponseEntity.ok(personas.findAll());
        
    }

    @GetMapping("/{id}")
    public ResponseEntity<Persona> getPersona(@PathVariable("id") Integer id){
        Persona persona = personas.findById(id);

        if (persona==null){
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(persona);

    }

    @PostMapping("/save")
    public ResponseEntity<Persona> guardarPersona(@Valid @RequestBody Persona entity, Errors errors) {

        try{
            if (errors.hasErrors()){
                return ResponseEntity.internalServerError().body(entity);
            }

            if (entity.getId() == null){
                entity.setUsuarioCreo("TEST");
            }
            //
            if (entity.getId() != null && personas.existsByID(entity.getId())){
                entity.setFechaActualizacion(new Date());
                entity.setUsuarioActualizo("Test");
            }
    
            Persona persona = personas.save(entity);
    
            if (persona==null){
                return ResponseEntity.internalServerError().body(entity);
            }
            
            return ResponseEntity.ok(persona);
        }catch (Exception e){
            e.printStackTrace();
            return ResponseEntity.internalServerError().body(entity);
        }
        
    }

    @PostMapping("/delete/{id}")
    public ResponseEntity<String> borrarPersona(@PathVariable("id") Integer id) {
        Persona persona = personas.findById(id);

        boolean result = personas.delete(persona);

        if (result){
            return ResponseEntity.ok("{ok:true}");
        }
        
        return ResponseEntity.notFound().build();
    }


}
