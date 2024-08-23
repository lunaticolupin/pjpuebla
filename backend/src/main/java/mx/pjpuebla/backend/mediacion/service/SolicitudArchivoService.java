package mx.pjpuebla.backend.mediacion.service;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Archivo;
import mx.pjpuebla.backend.mediacion.entitiy.SolicitudArchivo;
import mx.pjpuebla.backend.mediacion.repository.SolicitudArchivoRepository;

@Service
@AllArgsConstructor
public class SolicitudArchivoService {
    private final SolicitudArchivoRepository repo;

    public SolicitudArchivo save(SolicitudArchivo archivo) {
        return this.repo.save(archivo);
    }
    public SolicitudArchivo findById(String id){
        Optional<SolicitudArchivo> solicitudArchivo = this.repo.findById(id);
 
        if (solicitudArchivo.isPresent()){
            return solicitudArchivo.get();
        }
        return null;
    }

}
