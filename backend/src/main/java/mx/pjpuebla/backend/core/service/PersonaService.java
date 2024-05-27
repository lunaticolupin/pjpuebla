package mx.pjpuebla.backend.core.service;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;

import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.core.entitiy.Usuario;
import mx.pjpuebla.backend.core.repository.PersonaRepository;

@Service
@AllArgsConstructor
public class PersonaService {
    private final PersonaRepository repo;

    public List<Persona> findAll(){
        return repo.findAll();
    }

    public Persona save(Persona p){
        return this.repo.save(p);
    }

    
    public Persona findById(Integer id){
        Optional<Persona> persona = this.repo.findById(id);

        if(persona.isPresent()){
            return persona.get();
        }

        return null;
    }

    public boolean delete(Persona p){
        try{
            this.repo.delete(p);
            return true;
        }catch(Exception e){
            e.printStackTrace();
            return false;
        }
        
    }

    public boolean existsByID(Integer id){
        return this.repo.existsById(id);
    }

    public Persona findByCurpOrRfc(String valor){
        
        if(this.repo.existsByCurp(valor)){
            return this.repo.findByCurp(valor);
        }

        if(this.repo.existsByRfc(valor)){
            return this.repo.findByRfc(valor);
        }

        return null;
    }

}
