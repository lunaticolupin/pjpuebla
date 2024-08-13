package mx.pjpuebla.backend.mediacion.service;

import java.lang.StackWalker.Option;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;

import mx.pjpuebla.backend.mediacion.entitiy.Mediador;
import mx.pjpuebla.backend.mediacion.repository.MediadorRepository;

@Service
@AllArgsConstructor
public class MediadorService {
    private final MediadorRepository repo;
    
    
    public List<Mediador> findAll(){
        return repo.findAll();
    }


    public Mediador save(Mediador m){
        return repo.save(m);
    }

    public Mediador findById(Integer id){
        Optional<Mediador> mediador = this.repo.findById(id);

        if(mediador.isPresent()){
            return mediador.get();
        }
        
        return null;
    }

    public List<Mediador> obtenerMediadoresActivos() {
        return repo.findAllByEstatus(1);  // 1 representa el estatus activo
    }

    public boolean existsByID(Integer id){
        return this.repo.existsById(id);
    }
}
