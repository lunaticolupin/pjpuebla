package mx.pjpuebla.backend.core.service;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;

import mx.pjpuebla.backend.core.entitiy.Rol;
import mx.pjpuebla.backend.core.repository.RolRepository;

@Service
@AllArgsConstructor

public class RolService {

    private final RolRepository repo;

    public List<Rol> findAll() {
        return repo.findAll();
    }

    public List<Rol> findByActivo(boolean status) {
        return repo.findByActivo(status);
    }

    public Rol save(Rol r){
        return this.repo.save(r);
    }

    public Rol findById(Integer id) {
        Optional<Rol> rol =  this.repo.findById(id);

        if(rol.isPresent()){
            return rol.get();
        }

        return null;
    }

    public boolean delete(Rol r) {
        try {
            this.repo.delete(r);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean existsByID(Integer id) {
        return this.repo.existsById(id);
    }
}
