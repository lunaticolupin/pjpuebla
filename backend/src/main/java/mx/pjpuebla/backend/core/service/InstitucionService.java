package mx.pjpuebla.backend.core.service;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;
import mx.pjpuebla.backend.core.entitiy.Institucion;
import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.repository.InstitucionRepository;


@Service
@AllArgsConstructor
public class InstitucionService {
    private final InstitucionRepository repo;

    public List<Institucion> findAll(){
        return repo.findAll();
    }

    public Institucion save(Institucion i){
        return this.repo.save(i);
    }

    public Institucion findById(Integer id){
        Optional<Institucion> institucion = this.repo.findById(id);
        
        if(institucion.isPresent()){
            return institucion.get();
        }

        return null;
    }

    public boolean existsByID(Integer id){
        return this.repo.existsById(id);
    }

    public List<Institucion> obtenerInstitucionesActivas() {
        return repo.findAllByActivo(true);  
    }


}
