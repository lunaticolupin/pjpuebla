package mx.pjpuebla.backend.core.controller;

import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Materia;
import mx.pjpuebla.backend.core.service.MateriaService;
import mx.pjpuebla.backend.response.GenericResponse;

import java.sql.SQLException;

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
@RequestMapping("materias")
@RequiredArgsConstructor

public class MateriaController {
    private final MateriaService materias;

    @GetMapping("")
    public ResponseEntity<GenericResponse> getMaterias(){
        GenericResponse response = new GenericResponse();

        response.setSuccess(true);;
        response.setData(materias.findAll());

        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<GenericResponse> getMateria(@PathVariable("id") Integer id) {
        GenericResponse response = new GenericResponse();
        Materia materia = materias.findById(id);

        if(materia==null){
            response.setMessage("la materia no existe");;
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);

        }
        
        response.setSuccess(true);
        response.setData(materia);

        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/save")
    public ResponseEntity<GenericResponse> guardarMateria(@Valid @RequestBody Materia entity, Errors errors){
        GenericResponse response = new GenericResponse();
        try{
            if(errors.hasErrors()){
                response.setMessage("Materia no valida");
                response.setErrors(errors.getAllErrors());
                return ResponseEntity.internalServerError().body(response);

            }

            Materia materia = materias.save(entity);

            if (materia == null){
                response.setMessage("No se pudo guardar la materia");
                response.setData(entity);
                throw new SQLException(response.getMessage());
            }

            response.setSuccess(true);
            response.setMessage("OK");
            response.setData(materia);

            return ResponseEntity.ok(response);
        }catch (Exception e){
            e.printStackTrace();
            response.setMessage(e.getCause().getCause().getLocalizedMessage());

            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PostMapping("/delete/{id}")
    public ResponseEntity<GenericResponse> eliminarMateria(@PathVariable("id") Integer id) {
        Materia materia = materias.findById(id);
        GenericResponse response = new GenericResponse();

        if(materia == null){
            response.setMessage("La materia no existe");

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        try{
            materia.setActivo(false);

            materias.save(materia);
            String mensaje = String.format("la materia con ID %d fue eliminada", id);
            response.setSuccess(true);
            response.setMessage(mensaje);
            response.setData(materia);

            return ResponseEntity.ok(response);

        }catch (Exception e){
            response.setMessage(e.getCause().getCause().getLocalizedMessage());
            return ResponseEntity.internalServerError().body(response);
        }
        
    }
    
}
