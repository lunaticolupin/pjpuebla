package mx.pjpuebla.backend.mediacion.service;

import java.util.List;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.mediacion.entitiy.TipoApertura;
import mx.pjpuebla.backend.mediacion.repository.TipoAperturaRepository;

@Service
@AllArgsConstructor
public class TipoAperturaService {
    private final TipoAperturaRepository repositorio;

    public List<TipoApertura> findAll(){
        return this.repositorio.findAll();
    }

    public TipoApertura findByClave(String clave){
        return this.repositorio.findByClave(clave);
    }
}
