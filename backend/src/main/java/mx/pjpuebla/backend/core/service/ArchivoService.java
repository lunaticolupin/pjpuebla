package mx.pjpuebla.backend.core.service;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Archivo;
import mx.pjpuebla.backend.core.repository.ArchivoRepository;

@Service
@AllArgsConstructor
public class ArchivoService {
    private final ArchivoRepository repo;
    // private MultipartFile file;

    public Archivo findById(Long id){
        Optional<Archivo> archivo = this.repo.findById(id);

        if (archivo.isPresent()){
            return archivo.get();
        }

        return null;
    }

    public Long upload(MultipartFile file, String usuario){
        if (file.isEmpty()){
            return null;
        }

        String nombreArchivo = getNombre(file);
        String tipoArchivo = getTipo(file);
        byte[] dataArchivo = getBytes(file);

        return this.repo.uploadArchivo(nombreArchivo, tipoArchivo, dataArchivo, usuario);
    }

    @SuppressWarnings("unused")
    private Long uploadArchivo(String nombreArchivo, String tipoArchivo, byte[] dataArchivo, String usuario){
        return this.repo.uploadArchivo(nombreArchivo, tipoArchivo, dataArchivo, usuario);
    }

    private byte[] getBytes(MultipartFile file){
        try{
            return file.getBytes();
        }catch(IOException | NullPointerException e){
            return null;
        }
        
    }

    private String getTipo(MultipartFile file){
        try{
            return file.getContentType();
        }catch(NullPointerException e){
            return null;
        }
    }

    private String getNombre(MultipartFile file){
        
        try{
            String nombre = file.getOriginalFilename();
            return URLEncoder.encode(nombre, StandardCharsets.UTF_8.toString());
        }catch(UnsupportedEncodingException | NullPointerException e){
            return null;
        }

        
    }
}
