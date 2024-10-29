package mx.pjpuebla.backend.core.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Formato;
import mx.pjpuebla.backend.core.service.FormatoService;
import mx.pjpuebla.backend.response.GenericResponse;

import org.springframework.web.bind.annotation.RequestParam;


@RestController
@RequestMapping("formatos")
@RequiredArgsConstructor
public class FormatoController {
    private final FormatoService formatosService;
    private GenericResponse response;

    @GetMapping("")
    public ResponseEntity<GenericResponse> listar() {
        response = new GenericResponse(true, "OK", null, null);
        
        List<Formato> lista = formatosService.findAll();
        response.setData(lista);

        return ResponseEntity.ok(response);
    }
    
}
