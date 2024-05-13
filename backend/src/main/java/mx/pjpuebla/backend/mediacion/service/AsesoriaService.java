package mx.pjpuebla.backend.mediacion.service;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.mediacion.entitiy.Asesoria;
import mx.pjpuebla.backend.mediacion.repository.AsesoriaRepository;

@Service
@AllArgsConstructor
public class AsesoriaService {
    private final AsesoriaRepository repositorio;

    public List<Asesoria> findAll(){
        return this.repositorio.findAll();
    }

    public Asesoria findById(Integer id){
        Optional<Asesoria> asesoria = this.repositorio.findById(id);

        if (asesoria.isPresent()){
            return asesoria.get();
        }

        return null; 
    }
}
