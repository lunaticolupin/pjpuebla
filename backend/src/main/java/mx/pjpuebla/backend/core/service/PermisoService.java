package mx.pjpuebla.backend.core.service;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Permiso;
import mx.pjpuebla.backend.core.repository.PermisoRepository;
import mx.pjpuebla.backend.core.repository.RolRepository;

@Service
@AllArgsConstructor

public class PermisoService {
    private final PermisoRepository repo;

    public List<Permiso> findByActivo(boolean activo) {
        return repo.findByActivo(activo);
    }

    public List<Permiso> findAll() {
        return repo.findAll();
    }

    public Permiso save(Permiso p) {
        return this.repo.save(p);
    }

    public Permiso findById(Integer id) {
        Optional<Permiso> permiso =  this.repo.findById(id);

        if(permiso.isPresent()){
            return permiso.get();
        }

        return null;
    }

    public boolean delete(Permiso p) {
        try {
            this.repo.delete(p);
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
