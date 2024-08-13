package mx.pjpuebla.backend.core.controller;

import java.util.List;

import org.apache.catalina.connector.Response;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.Errors;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Institucion;
import mx.pjpuebla.backend.core.service.InstitucionService;
import mx.pjpuebla.backend.response.GenericResponse;

@RestController
@RequestMapping("instituciones")
@RequiredArgsConstructor
public class InstitucionController {
    private final InstitucionService instituciones;
    private GenericResponse response;

    @GetMapping("")
    public ResponseEntity<GenericResponse> listar() {
        response = new GenericResponse(true, "OK", null, null);
        
        List<Institucion > lista = instituciones.findAll();

        response.setData(lista);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/template")
    public ResponseEntity<GenericResponse> getJsonTemplate() {
        Institucion template = new Institucion();

        response = new GenericResponse(true, "OK", null, template);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/add")
    public ResponseEntity<GenericResponse> agregar(@Valid @RequestBody Institucion entidad, Errors  errors){
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

        Institucion nueva_institucion = instituciones.save(entidad);

        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(nueva_institucion);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/save/{id}")
    public ResponseEntity<GenericResponse> guardar(@Valid @RequestBody Institucion entidad, Errors errors){
        if (errors.hasErrors()){
            response.setMessage("La entidad tiene errores");
            response.setErrors(errors.getAllErrors());

            return ResponseEntity.badRequest().body(response);
        }

        Institucion institucion_actualizada = instituciones.save(entidad);
       
        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(institucion_actualizada);

        return ResponseEntity.ok(response);

    }


}
