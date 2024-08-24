package mx.pjpuebla.backend.core.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import io.jsonwebtoken.io.IOException;
// import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Archivo;
import mx.pjpuebla.backend.core.entitiy.Formato;
import mx.pjpuebla.backend.mediacion.entitiy.SolicitudArchivo;
import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.mediacion.service.SolicitudArchivoService;
import mx.pjpuebla.backend.core.service.ArchivoService;
import mx.pjpuebla.backend.response.GenericResponse;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import org.springframework.ui.Model;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;


import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.AbstractFileResolvingResource;
import org.springframework.core.io.UrlResource;
// import org.springframework.core.io.UrlResource;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.io.File;
import java.io.FileNotFoundException;
import java.net.MalformedURLException;

import org.springframework.core.io.Resource;

import java.util.HashMap;
import java.util.Map;

// import java.io.IOException;


@RestController
@RequiredArgsConstructor
@RequestMapping("archivos")
public class ArchivoController {

    private final ArchivoService archivos;
    private final SolicitudArchivoService solicitudArchivos;

    @Value("${file.upload-dir}")
    private String uploadDir;

    @PostMapping("/upload")
    public ResponseEntity<GenericResponse> uploadFile(@RequestParam("file") MultipartFile file, @RequestParam("solicitud_id") Long solicitud ,@RequestParam("formato_id") Integer formato, @RequestParam("usuario_creo") String usuario_creo) {
        
        GenericResponse response = new GenericResponse();
        try {

            // Integer usuario = usuario_creo;
            // Guardar el archivo en el servidor
            String fileName = file.getOriginalFilename();
            String filePath = uploadDir + File.separator + fileName;
            File dest = new File(filePath);
            file.transferTo(dest);

            // Generar la URL del archivo
            String fileDownloadUri = ServletUriComponentsBuilder.fromCurrentContextPath()
                    .path(uploadDir)
                    .path(fileName)
                    .toUriString();

            // archivo.setNombre(fileName);
            Archivo archivo = new Archivo();
            archivo.setNombre(fileName);
            archivo.setUsuario_creo(usuario_creo);
            archivos.save(archivo);

            SolicitudArchivo sa = new SolicitudArchivo();
            sa.setSolicitudId(solicitud);
            sa.setFormato(formato);
            sa.setArchivoId(archivo.id);
            sa.setEstatus(1);
            sa.setUsuarioCreo(usuario_creo);
            solicitudArchivos.save(sa);

            Map<String, Object> data = new HashMap<>();
            data.put("id", archivo.id);
            data.put("url", "http://localhost:8080/archivos/download/"+archivo.id);

            response.setSuccess(true);
            response.setMessage("Archivo almacenado con éxito");
            response.setData(data);
            // response.setData(archivo.nombre);


            return ResponseEntity.ok(response);
            // return new ResponseEntity<>(fileDownloadUri, HttpStatus.OK);

        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(response);
            // return new ResponseEntity<>("Error en la carga del archivo", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // @GetMapping("/download/{fileName}")
    // @GetMapping("/download/{fileName:.+}")
    @GetMapping("/download/{id}")
    // public ResponseEntity<Resource> downloadFile(@PathVariable String fileName, HttpServletRequest request) {
     public ResponseEntity<Resource> downloadFile(@PathVariable Integer id, HttpServletRequest request) {
        Archivo archivo = archivos.findById(id);
        // Cargar el archivo como un recurso
        Resource resource = loadFileAsResource(archivo.nombre);

        // Intentar determinar el tipo de contenido del archivo
        String contentType = null;
        try {
            contentType = request.getServletContext().getMimeType(resource.getFile().getAbsolutePath());
        } catch (Exception ex) {
            contentType = "application/octet-stream";
        }

        // Devolver el archivo con el tipo de contenido adecuado
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + resource.getFilename() + "\"")
                .body(resource);
    }

    // Método para cargar el archivo como un recurso
    private Resource loadFileAsResource(String fileName) {
        try {
            Path filePath = Paths.get(uploadDir).resolve(fileName).normalize();
            Resource resource = new UrlResource(filePath.toUri());
            if ( resource.exists()) {
                return resource;
            } else {
                throw new FileNotFoundException("Archivo no encontrado " + fileName);
            }
        } catch (MalformedURLException | FileNotFoundException ex) {
            throw new RuntimeException("Archivo no encontrado " + fileName, ex);
        }
    }
}
