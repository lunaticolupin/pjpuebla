package mx.pjpuebla.backend.core.controller;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Rol;
import mx.pjpuebla.backend.core.service.RolService;
import mx.pjpuebla.backend.response.GenericResponse;

import java.sql.SQLException;
import java.util.Date;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.Errors;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import jakarta.validation.Valid;


@RestController
@RequestMapping("roles")
@RequiredArgsConstructor

public class RolController {
    private final RolService roles;

    @GetMapping("all")
    public ResponseEntity<GenericResponse> getRolesAll() {
        GenericResponse response = new GenericResponse();

        response.setSuccess(true);
        response.setData(roles.findAll());
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("activos")
    public ResponseEntity<GenericResponse> getRolesActivos() {
        GenericResponse response = new GenericResponse();

        response.setSuccess(true);
        response.setData(roles.findByActivo(true));

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<GenericResponse> GetRol(@PathVariable("id") Integer id) {
        GenericResponse response = new GenericResponse();
        Rol rol = roles.findById(id);

        if(rol == null) {
            response.setMessage("El rol no existe");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        response.setSuccess(true);
        response.setData(rol);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/save")
    public ResponseEntity<GenericResponse> guardarRol(@Valid @RequestBody Rol entity, Errors errors) {    
        GenericResponse response = new GenericResponse();
        try {
            if(errors.hasErrors()) {
                response.setMessage("Rol no valido");
                response.setErrors(errors.getAllErrors());

                return ResponseEntity.internalServerError().body(response);
            }

            Rol rol = roles.save(entity);

            if(rol == null) {
                response.setMessage("no se pudo guardar el rol");
                response.setData(entity);

                throw new SQLException(response.getMessage());
            }

            response.setSuccess(true);
            response.setMessage("ok");
            response.setData(rol);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            e.printStackTrace();

            return ResponseEntity.internalServerError().body(response);
        }
        
    }

    @PostMapping("/delete/{id}")
    public ResponseEntity<GenericResponse> borrarRol(@PathVariable("id") Integer id) {
        Rol rol = roles.findById(id);

        GenericResponse response = new GenericResponse();

        if(rol ==  null) {
            response.setMessage("El rol no existe");

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        try {
            rol.setActivo(false);
            roles.save(rol);

            String mensaje = String.format("Rol %d fue eliminado con éxito");
            response.setSuccess(true);
            response.setMessage(mensaje);
            response.setData(rol);

            return ResponseEntity.ok(response);

        }catch (Exception e) {
            return ResponseEntity.internalServerError().body(response);
        }
    }
    
    
    
    
}
