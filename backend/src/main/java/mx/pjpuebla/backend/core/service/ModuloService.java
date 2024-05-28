package mx.pjpuebla.backend.core.service;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;

import mx.pjpuebla.backend.core.repository.ModuloRepository;
import mx.pjpuebla.backend.core.entitiy.Modulo;

@Service
@AllArgsConstructor
public class ModuloService {
    private final ModuloRepository repo;

    public List<Modulo> findAll(){
        return repo.findAll();
    }

    public List<Modulo> findByActivo(boolean activo) {
        return repo.findByActivo(activo);
    }

    public Modulo save(Modulo m){
        return this.repo.save(m);
    }

    public Modulo findById(Integer id){
        Optional<Modulo> modulo = this.repo.findById(id);

        if(modulo.isPresent()){
            return modulo.get();
        }

        return null;
    }

    public boolean delete (Modulo m){
        try{
            this.repo.delete(m);
            return true;
        }catch(Exception e){
            e.printStackTrace();
            return false;
        }
    }

    public boolean existsByID(Integer id){
        return this.repo.existsById(id);
    }
    
}
