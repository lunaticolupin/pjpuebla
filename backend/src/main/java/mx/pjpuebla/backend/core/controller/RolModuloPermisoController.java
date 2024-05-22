package mx.pjpuebla.backend.core.controller;

import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.RolModuloPermiso;
import mx.pjpuebla.backend.core.service.RolModuloPermisoService;
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
import org.springframework.web.bind.annotation.RequestParam;
import mx.pjpuebla.backend.core.entitiy.RolModuloPermisoKey;


@RestController
@RequestMapping("rolmodulopermisos")
@RequiredArgsConstructor

public class RolModuloPermisoController {

    private final RolModuloPermisoService rolmodulopermisos;

    @GetMapping("")
    public ResponseEntity<GenericResponse> getRolModuloPermisos() {

        GenericResponse response = new GenericResponse();

        response.setSuccess(true);
        response.setData(rolmodulopermisos.findAll());;

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<GenericResponse> getRolModuloPErmiso(@PathVariable("id") RolModuloPermisoKey id) {
        GenericResponse response = new GenericResponse();
        RolModuloPermiso rolUsuarioPermiso = rolmodulopermisos.findById(id);

        if(rolUsuarioPermiso == null) {
            response.setMessage("EL registro no existe");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
        response.setSuccess(true);
        response.setData(rolUsuarioPermiso);
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/save")
    public ResponseEntity<GenericResponse> guardarRolModuloPermiso(@Valid @RequestBody RolModuloPermiso entity, Errors errors) {
        GenericResponse response = new GenericResponse();
        try {
            if(errors.hasErrors()) {
                response.setMessage("Datos invalidos");
                response.setErrors(errors.getAllErrors());

                return ResponseEntity.internalServerError().body(response);
            }

                RolModuloPermiso rmp = rolmodulopermisos.save(entity);

                if(rmp == null) {
                    response.setMessage("No se pudo guardar el registro");
                    response.setData(entity);

                    throw new SQLException(response.getMessage());
                }

                response.setSuccess(true);
                response.setMessage("ok");
                response.setData(rmp);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            response.setMessage(e.getCause().getCause().getLocalizedMessage());

            return ResponseEntity.internalServerError().body(response);
        }
    }
    
    
    
    
}
