package mx.pjpuebla.backend.mediacion.controller;

import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.Errors;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.core.service.PersonaService;
import mx.pjpuebla.backend.mediacion.entitiy.Mediador;
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.service.MediadorService;
import mx.pjpuebla.backend.response.GenericResponse;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@RestController
@RequestMapping("mediacion/mediadores")
@RequiredArgsConstructor
public class MediadorController {
    private final MediadorService mediadores;
    private GenericResponse response;
    private PersonaService persona;

    @GetMapping("")
    public ResponseEntity<GenericResponse> getMediadores() {
        GenericResponse response = new GenericResponse();

        response.setSuccess(true);
        response.setData(mediadores.findAll());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/activos")
    public ResponseEntity<GenericResponse> getMediadoresActivos() {
        GenericResponse response = new GenericResponse();

        response.setSuccess(true);
        response.setData(mediadores.obtenerMediadoresActivos());

        return ResponseEntity.ok(response);
    }

    @GetMapping("template")
    public ResponseEntity<GenericResponse> getJsonTemplate() {
        Mediador template = new Mediador();
        Persona persona = new Persona();

        template.setUsuario(persona);

        response = new GenericResponse(true, "OK", null, template);

        return ResponseEntity.ok(response);
    }

    @GetMapping("numeroConsecutivo")
    public ResponseEntity<GenericResponse> getNumeroConsecutivo() {
        GenericResponse response = new GenericResponse();

        response.setSuccess(true);
        response.setData(mediadores.obtenerNumeroConsecutivoMediador());

        return ResponseEntity.ok(response);
    }

    @PostMapping("/add")
    public ResponseEntity<GenericResponse> agregar(@Valid @RequestBody Mediador entidad, Errors errors) {
        try {

            response = new GenericResponse();

            entidad.setUsuarioRegistro("TEST");

            if (errors.hasErrors()) {
                response.setMessage("La entidad tiene errores");
                response.setErrors(errors.getAllErrors());

                return ResponseEntity.badRequest().body(response);
            }

            if (entidad.getId() != null) {
                response.setMessage("La entidad ya existe");

                return ResponseEntity.badRequest().body(response);
            }

            Mediador nuevo_mediador = mediadores.save(entidad);
            response.setSuccess(true);
            response.setMessage("OK");
            response.setData(nuevo_mediador);

            return ResponseEntity.ok(response);

        } catch (DataIntegrityViolationException e) {
            response = new GenericResponse();
            e.printStackTrace();
            String errorMessage;
            List<String> errorList = new ArrayList<>(Arrays.asList("El usuario seleccionado ya se encuentra registrado como mediador."));
            

            errorMessage = "Mediador registrado";

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
    public ResponseEntity<GenericResponse> guardar(@Valid @RequestBody Mediador entidad, Errors errors) {
        GenericResponse response = new GenericResponse();

        try {

            if (errors.hasErrors()) {
                response.setMessage("La entidad tiene errores");
                response.setErrors(errors.getAllErrors());
                return ResponseEntity.badRequest().body(response);
            }

            if (entidad.getId() != null && mediadores.existsByID(entidad.getId())) {
                entidad.setFechaActualizacion(new Date());
                entidad.setUsuarioActualizo("Test");
            }

            Mediador mediadorActualizado = mediadores.save(entidad);
            if (mediadorActualizado == null) {
                response.setMessage("No se pudo guardar la entidad");
                response.setData(entidad);
                throw new SQLException(response.getMessage());
            }

            response.setSuccess(true);
            response.setMessage("OK");
            response.setData(mediadorActualizado);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            e.printStackTrace();
            response.setMessage(e.getCause().getCause().getLocalizedMessage());

            return ResponseEntity.internalServerError().body(response);
        }

    }

}
