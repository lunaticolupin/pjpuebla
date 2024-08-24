package mx.pjpuebla.backend.mediacion.controller;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.Errors;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.core.service.PersonaService;
import mx.pjpuebla.backend.mediacion.entitiy.Psicologo;
import mx.pjpuebla.backend.mediacion.service.PsicologoService;
import mx.pjpuebla.backend.response.GenericResponse;

@RestController
@RequestMapping("mediacion/psicologos")
@RequiredArgsConstructor
public class PsicologoController {
    private final PersonaService personas;
    private GenericResponse response;
    private final PsicologoService psicologos;

    @GetMapping("")
    public ResponseEntity<GenericResponse> listar() {
        GenericResponse response = new GenericResponse();

        response.setSuccess(true);
        response.setData(psicologos.findAll());

        return ResponseEntity.ok(response);
    }

    @GetMapping("template")
    public ResponseEntity<GenericResponse> getJsonTemplate() {
        Psicologo template = new Psicologo();
        Persona persona = new Persona();

        template.setUsuario(persona);

        response = new GenericResponse(true, "OK", null, template);

        return ResponseEntity.ok(response);
    }

    @GetMapping("numeroConsecutivo")
    public ResponseEntity<GenericResponse> getNumeroConsecutivo() {
        GenericResponse response = new GenericResponse();

        response.setSuccess(true);
        response.setData(psicologos.obtenerNumeroConsecutivoPsicologo());

        return ResponseEntity.ok(response);
    }

    @PostMapping("/add")
    public ResponseEntity<GenericResponse> agregar(@Valid @RequestBody Psicologo entidad, Errors errors) {
        try {
            response = new GenericResponse();

            if (errors.hasErrors()) {
                response.setMessage("La entidad tiene errores");
                response.setErrors(errors.getAllErrors());

                return ResponseEntity.badRequest().body(response);
            }

            if (entidad.getId() != null) {
                response.setMessage("La entidad ya existe");

                return ResponseEntity.badRequest().body(response);
            }

            Psicologo nuevo_psicologo = psicologos.save(entidad);
            response.setSuccess(true);
            response.setMessage("OK");
            response.setData(nuevo_psicologo);

            return ResponseEntity.ok(response);
            
        } catch (DataIntegrityViolationException e) {
            response = new GenericResponse();
            e.printStackTrace();
            String errorMessage;
            List<String> errorList = new ArrayList<>(
                    Arrays.asList("El usuario seleccionado ya se encuentra registrado como psicólogo."));

            errorMessage = "Psicologo registrado";

            response.setMessage(errorMessage);
            response.setSuccess(false);
            response.setErrors(errorList);
            return ResponseEntity.badRequest().body(response);
        }

        catch (Exception e) {
            // TODO: handle exception
        }

        return null;
    }

    @PostMapping("/save/{id}")
    public ResponseEntity<GenericResponse> guardar(@Valid @RequestBody Psicologo entidad, Errors errors) {
        response = new GenericResponse();

        if (errors.hasErrors()) {
            response.setMessage("La entidad tiene errores");
            response.setErrors(errors.getAllErrors());
            return ResponseEntity.badRequest().body(response);
        }

        Psicologo psicologoActualizado = psicologos.save(entidad);
        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(psicologoActualizado);

        return ResponseEntity.ok(response);
    }

    @PostMapping("/delete/{id}")
    public ResponseEntity<GenericResponse> eliminar(@PathVariable("id") Integer id) {
        response = new GenericResponse();

        if (psicologos.esEliminable(id)) {
            response.setSuccess(psicologos.delete(id));
            response.setMessage("Psicologo eliminado");
            return ResponseEntity.ok(response);
        }

        response.setMessage("El psicólogo ha sido eliminado");

        return ResponseEntity.badRequest().body(response);
    }

}
