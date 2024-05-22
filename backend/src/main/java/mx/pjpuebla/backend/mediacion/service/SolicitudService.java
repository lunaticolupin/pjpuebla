package mx.pjpuebla.backend.mediacion.service;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Usuario;
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.repository.SolicitudRepository;
import mx.pjpuebla.backend.models.SolicitudMediacionEstatus;

@Service
@AllArgsConstructor
public class SolicitudService {
    private final SolicitudRepository repositorio;

    public List<Solicitud> findAll(){
        return this.repositorio.findAll();
    }

    public Solicitud findById(Integer id){
        Optional<Solicitud> solicitud = this.repositorio.findById(id);

        if (solicitud.isPresent()){
            return solicitud.get();
        }

        return null;
    }

    public Solicitud findByFolio(String folio){
        return this.repositorio.findByFolio(folio);
    }

    public Solicitud save(Solicitud solicitud){
        return this.repositorio.save(solicitud);
    }

    public boolean delete(Integer id){
        try{
            this.repositorio.deleteById(id);

            return true;
        }catch(Exception e){
            return false;
        }
    }

    public String generarFolio(String claveArea){
        return this.repositorio.generarFolio(claveArea);
    }

    public boolean esEliminable(Integer id){
        Optional<Solicitud> solicitud = this.repositorio.findById(id);

        if (solicitud.isEmpty()){
            return false;
        }

        return solicitud.get().getEstatus()!= SolicitudMediacionEstatus.RECEPCION;
    }
}
