package mx.pjpuebla.backend.core.service;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Formato;
import mx.pjpuebla.backend.core.repository.FormatoRepository;
import mx.pjpuebla.backend.mediacion.entitiy.SolicitudArchivo;

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

    public Formato findById(Integer id){
        Optional<Formato> formato = this.repositorio.findById(id);
        if(formato.isPresent()){
            return formato.get();
        }

        return null;


    }


}
