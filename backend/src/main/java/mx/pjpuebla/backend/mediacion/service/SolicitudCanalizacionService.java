package mx.pjpuebla.backend.mediacion.service;

import java.util.Optional;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.mediacion.repository.SolicitudCanalizacionRepository;
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.entitiy.SolicitudCanalizacion;

@Service
@AllArgsConstructor
public class SolicitudCanalizacionService {
    private final  SolicitudCanalizacionRepository repo;
    
    public SolicitudCanalizacion save(SolicitudCanalizacion sc){
        return this.repo.save(sc);
    }

    public SolicitudCanalizacion findById(Integer id){
        Optional <SolicitudCanalizacion> solicitud_canalizacion = repo.findById(id);
        
        if(solicitud_canalizacion.isPresent()){
            return solicitud_canalizacion.get();
        }
        
        return null;
    }

}
