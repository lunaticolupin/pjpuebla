package mx.pjpuebla.backend.core.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Archivo;
import mx.pjpuebla.backend.core.service.ArchivoService;
import mx.pjpuebla.backend.response.GenericResponse;

import java.util.Arrays;

import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;



@RestController
@RequiredArgsConstructor
@RequestMapping("archivos")
public class ArchivoController {
    private final ArchivoService archivos;

    @GetMapping("/{id}")
    public ResponseEntity<?> getArchivo(@PathVariable("id") Long archivoId) {
        Archivo archivo = archivos.findById(archivoId);

        if (archivo==null){
            GenericResponse response = new GenericResponse();
            response.setMessage("Archivo no encontrado");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        return ResponseEntity.ok()
        .contentLength(archivo.getData().length)
        .header("Content-Type",archivo.getTipo())
        .header("content-disposition", "filename=".concat(archivo.getNombre()))
        .body(archivo.getData());
    }
    

    @PostMapping("upload")
    public ResponseEntity<GenericResponse> upload(@RequestParam("archivo") MultipartFile archivo) {
        //TODO: process POST request
        GenericResponse response = new GenericResponse();

        try{
            Long archivoId = archivos.upload(archivo, "TEST");

            if (archivoId==null){
                throw new Exception("Error al guardar el archivo");
            }
            //Archivo entity = archivos.findById(archivoId);

            response.setSuccess(true);
            response.setData(archivoId);

            return ResponseEntity.ok(response);
        }catch(Exception e){
            response.setMessage("No se pudo subir el archivo");
            response.setErrors(Arrays.asList(e.getMessage()));

            e.printStackTrace();

            return ResponseEntity.internalServerError().body(response);
        }
        
    }
    
}
