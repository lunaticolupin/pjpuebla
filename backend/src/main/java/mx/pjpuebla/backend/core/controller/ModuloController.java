package mx.pjpuebla.backend.core.controller;

import java.sql.SQLException;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.Errors;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Modulo;
import mx.pjpuebla.backend.core.service.ModuloService;
import mx.pjpuebla.backend.response.GenericResponse;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PostMapping;



@RestController
@RequestMapping("modulos")
@RequiredArgsConstructor
public class ModuloController {
     private final ModuloService modulos;

    @GetMapping("")
    public ResponseEntity<GenericResponse> getModulosAll(){
        GenericResponse response = new GenericResponse();
        
        response.setSuccess(true);
        response.setData(modulos.findAll());

        return ResponseEntity.ok(response);

    }

    @GetMapping("activos")
    public ResponseEntity<GenericResponse> getModulosActivos(){
        GenericResponse response = new GenericResponse();
        
        response.setSuccess(true);
        response.setData(modulos.findByActivo(true));

        return ResponseEntity.ok(response);

    }

    @GetMapping("/{id}")
    public ResponseEntity<GenericResponse> getModulo(@PathVariable("id") Integer id) {
        GenericResponse response = new GenericResponse();
        Modulo modulo = modulos.findById(id);
        
        if(modulo == null ){
            response.setMessage("El modulo no existe");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        response.setSuccess(true);
        response.setData(modulo);


        return ResponseEntity.ok(response);
    }

    @PostMapping("/save")
    public ResponseEntity<GenericResponse> guardarModulo(@Valid @RequestBody Modulo entity, Errors errors) {
        GenericResponse response = new GenericResponse();
        try {
            if(errors.hasErrors()){
                response.setMessage("Modulo no valido");
                response.setErrors(errors.getAllErrors());
                return ResponseEntity.internalServerError().body(response);
            }
            Modulo modulo = modulos.save(entity);

            if(modulo==null){
                response.setMessage("No se pudo guardar el Modulo");
                response.setData(entity);
                throw new SQLException(response.getMessage());
            }

            response.setSuccess(true);
            response.setMessage("OK");
            response.setData(modulo);

            return ResponseEntity.ok(response);
        
        } catch (Exception e) {
            e.printStackTrace();
            response.setMessage(e.getCause().getCause().getLocalizedMessage());

            return ResponseEntity.internalServerError().body(response);
        }
    }
     
    @PostMapping("/delete/{id}")
    public ResponseEntity<GenericResponse> borarrModulo(@PathVariable("id") Integer id) {
        Modulo modulo = modulos.findById(id);
        GenericResponse response = new GenericResponse();

        if(modulo == null){
            response.setMessage("El Id no existe");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        try {

            modulo.setActivo(false);
            modulos.save(modulo);

            String mensaje = String.format("El modulo con el ID %d fue dado de baja con éxito", id);
            response.setSuccess(true);
            response.setMessage(mensaje);
            response.setData(modulo);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            response.setMessage(e.getCause().getCause().getLocalizedMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
     
     
    
}
