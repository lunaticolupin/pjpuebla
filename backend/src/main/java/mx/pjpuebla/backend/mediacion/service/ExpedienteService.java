package mx.pjpuebla.backend.mediacion.service;

import java.util.Optional;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.mediacion.entitiy.Expediente;
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.repository.ExpedienteRepository;
import mx.pjpuebla.backend.response.GenericResponse;
import lombok.AllArgsConstructor;

@Service
@AllArgsConstructor
public class ExpedienteService {
    private final ExpedienteRepository repositorio;

    public Expediente save(Expediente expediente) {
        return this.repositorio.save(expediente);
    }
    public Expediente findBySolicitud(Integer solicitud_id) {
        Optional<Expediente> expediente = this.repositorio.findBySolicitud(solicitud_id);
        // return this.repositorio.findBySolicitud(solicitud_id);
        if (expediente.isPresent()) {
            return expediente.get();
        }
        return null;
    }

    public Integer getFolio(){
        return this.repositorio.getFolio();
    }
    
}
