package mx.pjpuebla.backend.core.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;

import mx.pjpuebla.backend.core.service.MateriasService;
import mx.pjpuebla.backend.response.GenericResponse;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;

@RestController
@RequiredArgsConstructor
@RequestMapping("materias")
public class MateriasController {
    private final MateriasService materias;
    private GenericResponse response;

    @GetMapping("")
    public ResponseEntity<GenericResponse> lista() {
        response = new GenericResponse();

        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(materias.findAll());

        return ResponseEntity.ok(response);
    }
}
