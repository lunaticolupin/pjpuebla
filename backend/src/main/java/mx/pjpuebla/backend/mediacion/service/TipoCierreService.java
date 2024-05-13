package mx.pjpuebla.backend.mediacion.service;

import java.util.List;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.mediacion.entitiy.TipoCierre;
import mx.pjpuebla.backend.mediacion.repository.TipoCierreRepository;

@Service
@AllArgsConstructor
public class TipoCierreService {
    private final TipoCierreRepository repositorio;

    public List<TipoCierre> findAll(){
        return this.repositorio.findAll();
    }

    public TipoCierre findByClave(String clave){
        return this.repositorio.findByClave(clave);
    }
}
