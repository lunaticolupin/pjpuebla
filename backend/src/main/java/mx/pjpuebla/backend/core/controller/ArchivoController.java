package mx.pjpuebla.backend.core.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import io.jsonwebtoken.io.IOException;
// import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.DTO.FileInfoDto;
import mx.pjpuebla.backend.core.entitiy.Archivo;
import mx.pjpuebla.backend.core.entitiy.Formato;
import mx.pjpuebla.backend.mediacion.entitiy.SolicitudArchivo;
import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.mediacion.service.SolicitudArchivoService;
import mx.pjpuebla.backend.core.service.ArchivoService;
import mx.pjpuebla.backend.core.service.FormatoService;
import mx.pjpuebla.backend.response.GenericResponse;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
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
import org.springframework.beans.factory.annotation.Autowired;
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
import java.util.List;
import java.util.Map;
import java.util.UUID;

// import javax.servlet.http.HttpServletRequest;
// import javax.servlet.http.HttpServletRequest;
// import java.io.IOException;


@RestController
//@RequiredArgsConstructork
@RequestMapping("archivos")
public class ArchivoController {

    @Autowired
    private  ArchivoService archivos;

    @Autowired
    private  SolicitudArchivoService solicitudArchivos;
    
    @Autowired
    private  FormatoService formatoService;

    @Value("${file.upload-dir}")
    private String uploadDir;

    @PostMapping("/create")
    public ResponseEntity<GenericResponse> createRecordFile(@RequestParam("solicitud_id") Integer solicitud ,@RequestParam("formato_id") Integer formato_id, @RequestParam("usuario_creo") String usuario_creo) {
        
        GenericResponse response = new GenericResponse();
        Archivo archivo;
        try {
            Formato formato = formatoService.findById(formato_id);
            
            if(solicitudArchivos.findBySolicitudIdAndFormato(solicitud, formato_id) == null){

                archivo = new Archivo();
                archivo.setUsuario_creo(usuario_creo);
                archivo.setNombre("");
                archivo.setTipo(formato.getDescripcion());
                archivo.setEstatus(1);
                archivos.save(archivo);
    
                SolicitudArchivo sa = new SolicitudArchivo();
                sa.setSolicitudId(solicitud);
                sa.setFormato(formato_id);
                sa.setArchivoId(archivo.id);
                sa.setEstatus(1);
                sa.setUsuarioCreo(usuario_creo);
                solicitudArchivos.save(sa);

                response.setSuccess(true);
                response.setMessage("ok");
                
                return ResponseEntity.ok(response);
            }else {
                List<String> errores = new ArrayList<>();
                errores.add("El documeto que esta tratando de agregar ya se encuentra registrado.");
                response.setSuccess(false);
                response.setMessage("Error: documento registrado.");
                response.setErrors(errores);
                return ResponseEntity.ok(response);
            }
        } catch (Exception e) {
            System.out.println(e);
            return ResponseEntity.internalServerError().body(response);
            // return new ResponseEntity<>("Error en la carga del archivo", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    
    @GetMapping("/list")
    public ResponseEntity<GenericResponse> getFileInfo(@RequestParam("solicitud_id") Integer solicitudId) {
        GenericResponse response = new GenericResponse();
        List<FileInfoDto> fileInfoList = archivos.getFileInfo(solicitudId);
        
        response.setSuccess(true);
        response.setMessage("ok");
        response.setData(fileInfoList);

        return ResponseEntity.ok(response);
    }


    @PostMapping("/upload")
    public ResponseEntity<GenericResponse> uploadFile(@RequestParam("file") MultipartFile file, @RequestParam("solicitud_id") Integer solicitud ,@RequestParam("formato_id") Integer formato, @RequestParam("usuario_creo") String usuario_creo, @RequestParam("archivo_id") Integer archivo_id ) {
        
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
            Archivo archivo = archivos.findById(archivo_id);
            

            archivo.setNombre(fileName);
            archivo.setUsuario_creo(usuario_creo);
            archivos.save(archivo);

            SolicitudArchivo sa = solicitudArchivos.findBySolicitudIdAndArchivoId(solicitud, archivo.id);
            sa.setFormato(formato);
            sa.setArchivoId(archivo.id);
            sa.setEstatus(1);
            sa.setUsuarioActualizo(usuario_creo);
            solicitudArchivos.save(sa);

            // jakarta.servlet.http.HttpServletRequest request;
            // String url = this.getUrl(request);

            // String url = this.getUrl(null);

            // String url = this.getUrl(request);

            Map<String, Object> data = new HashMap<>();
            data.put("id", archivo.id);
            // data.put("url", "http://localhost:8080/archivos/download/"+archivo.id);
            // data.put("url",url );

            response.setSuccess(true);
            response.setMessage("Archivo almacenado con éxito");
            response.setData(data);
            // response.setData(archivo.nombre);


            return ResponseEntity.ok(response);
            // return new ResponseEntity<>(fileDownloadUri, HttpStatus.OK);

        } catch (Exception e) {
            System.out.println(e);
            return ResponseEntity.internalServerError().body(response);
            // return new ResponseEntity<>("Error en la carga del archivo", HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PostMapping("/delete")
    public ResponseEntity<GenericResponse> deleteFile( @RequestBody Map<String, Object> requestBody) {
        //boorado logico de las tablas solicitud y archivos
        GenericResponse response = new GenericResponse();
        Integer archivoId = (Integer) requestBody.get("archivoId");;
        UUID solicitudArchivoId = UUID.fromString((String) requestBody.get("solicitudArchivoId"));
        String usuarioActualizo = (String) requestBody.get("usuarioActualizo");

        // Cambiamos estatus del archivo
        Archivo archivo = archivos.findById(archivoId);
        archivo.setNombre("");
        archivo.setEstatus(0);
        archivos.save(archivo);


        SolicitudArchivo solicitud = solicitudArchivos.findById(solicitudArchivoId);
        
        solicitud.setEstatus(0);
        solicitudArchivos.save(solicitud);
        response.setSuccess(true);
        response.setMessage("Archivo eliminado con éxito");

        return ResponseEntity.ok(response);
    }
    

    // @GetMapping("/download/{fileName}")
    // @GetMapping("/download/{fileName:.+}")
    @GetMapping("/download/{id}")
    public ResponseEntity<Resource> downloadFile(@PathVariable Integer id, HttpServletRequest request) {
        Archivo archivo = archivos.findById(id);
        Resource resource = loadFileAsResource(archivo.getNombre());
    
        String contentType = null;
        try {
            contentType = request.getServletContext().getMimeType(resource.getFile().getAbsolutePath());
        } catch (Exception ex) {
            contentType = "application/octet-stream";
        }
    
        // Exponer el encabezado Content-Disposition
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + resource.getFilename() + "\"")
                .header(HttpHeaders.ACCESS_CONTROL_EXPOSE_HEADERS, HttpHeaders.CONTENT_DISPOSITION)
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

    // @GetMapping("/get-url")
    public String getUrl(HttpServletRequest request) {
        String url = request.getLocalAddr();
        // String url = request.getRequestURL().toString();
        return url;
    }
}
