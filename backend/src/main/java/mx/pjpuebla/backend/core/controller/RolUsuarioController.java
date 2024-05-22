package mx.pjpuebla.backend.core.controller;

import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.RolUsuario;
import mx.pjpuebla.backend.core.entitiy.RolUsuarioKey;
import mx.pjpuebla.backend.core.service.RolUsuarioService;
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
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;


@RestController
@RequestMapping("rolesUsuario")
@RequiredArgsConstructor


public class RolUsuarioController {

    private final RolUsuarioService rolesUsuario;

    @GetMapping("")
    public ResponseEntity<GenericResponse> getRolesUsuario() {
        GenericResponse response = new GenericResponse();

        response.setSuccess(true);
        response.setData(rolesUsuario.findAll());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<GenericResponse> GetRol(@PathVariable("id") RolUsuarioKey id) {
        GenericResponse response = new GenericResponse();
        RolUsuario rolUsuario = rolesUsuario.findById(id);

        if(rolUsuario == null) {
            response.setMessage("El rol no existe");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        response.setSuccess(true);
        response.setData(rolUsuario);

        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/save")
    public ResponseEntity<GenericResponse> guardarRolUsuario(@Valid @RequestBody RolUsuario entity, Errors errors) {
        
        GenericResponse response =  new GenericResponse();
        try {
            if(errors.hasErrors()) {
                response.setMessage("Rol de usuario invalido");
                response.setErrors(errors.getAllErrors());

                return ResponseEntity.internalServerError().body(response);
            }

            RolUsuario ru = rolesUsuario.save(entity);

            if(ru == null) {
                response.setMessage("No se pudo guardar el rol de usuario");
                response.setData(entity);

                throw new SQLException(response.getMessage());
            }

            response.setSuccess(true);
            response.setMessage("ok");
            response.setData(ru);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            e.printStackTrace();
            // response.setMessage(e.getCause().getCause().getLocalizedMessage());

            return ResponseEntity.internalServerError().body(response);        
        }        
    }
    
}
