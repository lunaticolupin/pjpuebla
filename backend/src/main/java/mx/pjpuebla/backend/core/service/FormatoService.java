package mx.pjpuebla.backend.core.service;

import java.util.List;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Formato;
import mx.pjpuebla.backend.core.repository.FormatoRepository;

@Service
@AllArgsConstructor
public class FormatoService {
    private final FormatoRepository repositorio;

    public List<Formato> findAll(){
        return repositorio.findAll();
    }

    public List<Formato> findNombreReporte(String nombre){
        return repositorio.findByNombreReporte(nombre);
    }

}
