package mx.pjpuebla.backend.core.controller;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Permiso;
import mx.pjpuebla.backend.core.service.PermisoService;
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
@RequestMapping("permisos")
@RequiredArgsConstructor

public class PermisoController {
     private final PermisoService permisos;

    @GetMapping("")
    public ResponseEntity<GenericResponse> getPermisos() {
        GenericResponse response = new GenericResponse();
        
        response.setSuccess(true);
        response.setData(permisos.findAll());
        
        return ResponseEntity.ok(response);         
    }

    @GetMapping("activos")
    public ResponseEntity<GenericResponse> getPermisosActivos() {
        GenericResponse response = new GenericResponse();
        
        response.setSuccess(true);
        response.setData(permisos.findByActivo(true));
        
        return ResponseEntity.ok(response);         
    }

    @GetMapping("/{id}")
    public ResponseEntity<GenericResponse> GetPermiso(@PathVariable("id") Integer id) {
        GenericResponse response = new GenericResponse();
        Permiso permiso = permisos.findById(id);

        if(permiso == null) {
            response.setMessage("El rol no existe");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        response.setSuccess(true);
        response.setData(permiso);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/save")
    public ResponseEntity<GenericResponse> guardarPermiso(@Valid @RequestBody Permiso entity, Errors errors) {    
        GenericResponse response = new GenericResponse();
        try {
            if(errors.hasErrors()) {
                response.setMessage("Rol no valido");
                response.setErrors(errors.getAllErrors());

                return ResponseEntity.internalServerError().body(response);
            }

            Permiso permiso = permisos.save(entity);

            if(permiso == null) {
                response.setMessage("no se pudo guardar el permiso");
                response.setData(entity);

                throw new SQLException(response.getMessage());
            }

            response.setSuccess(true);
            response.setMessage("ok");
            response.setData(permiso);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            e.printStackTrace();
            response.setMessage(e.getCause().getCause().getLocalizedMessage());

            return ResponseEntity.internalServerError().body(response);
        }
        
    }

    @PostMapping("/delete/{id}")
    public ResponseEntity<GenericResponse> borrarPermiso(@PathVariable("id") Integer id) {
        Permiso permiso = permisos.findById(id);

        GenericResponse response = new GenericResponse();

        if(permiso ==  null) {
            response.setMessage("El permiso no existe");

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        try {
            permiso.setActivo(false);
            permisos.save(permiso);

            String mensaje = String.format("permiso %d fue dado de baja con éxito",id);
            response.setSuccess(true);
            response.setMessage(mensaje);
            response.setData(permiso);

            return ResponseEntity.ok(response);

        }catch (Exception e) {
            response.setMessage(e.getCause().getCause().getLocalizedMessage());
            return ResponseEntity.internalServerError().body(response);
        }
    }
    
}
