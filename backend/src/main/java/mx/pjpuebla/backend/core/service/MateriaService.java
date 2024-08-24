package mx.pjpuebla.backend.core.service;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;

import mx.pjpuebla.backend.core.entitiy.Materia;
import mx.pjpuebla.backend.core.repository.MateriaRepository;

@Service
@AllArgsConstructor
public class MateriaService {
    private final MateriaRepository repo;

    public List<Materia> findAll(){
        return repo.findAll();
    }

    public Materia save(Materia m){
        return this.repo.save(m);
    }

    public boolean delete(Materia m){
        try{
            this.repo.delete(m);
            return true;
        }catch(Exception e){
            e.printStackTrace();
            return false;
        }
    }

    public Materia findById(Integer id){
        Optional<Materia> materia = this.repo.findById(id);

        if(materia.isPresent()){
            return materia.get();
        }

        return null;
    }

    public boolean existsByID(Integer id){
        return this.repo.existsById(id);
    }
}