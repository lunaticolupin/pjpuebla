package mx.pjpuebla.backend.mediacion.service;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Optional;
import java.util.UUID;

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
    public SolicitudArchivo findById(UUID id){
        Optional<SolicitudArchivo> solicitudArchivo = this.repo.findById(id);
        System.out.println("el id ocupado es: " + id);
        
        if (solicitudArchivo.isPresent()){
            System.out.println("Encontre la entidad");
            solicitudArchivo.get().getId();
            return solicitudArchivo.get();
        }
        return null;
    }

    public SolicitudArchivo findBySolicitudId(Integer id){
        return repo.findBySolicitudId(id);
    }

    public SolicitudArchivo findBySolicitudIdAndFormato(Integer solicitud_id, Integer formato_id) {
        return repo.findBySolicitudIdAndFormatoAndEstatus(solicitud_id, formato_id, 1);
    }
    

    public SolicitudArchivo findBySolicitudIdAndArchivoId(Integer solicitud_id, Integer archivo_id){
        return repo.findBySolicitudIdAndArchivoId(solicitud_id, archivo_id);
    }

}
