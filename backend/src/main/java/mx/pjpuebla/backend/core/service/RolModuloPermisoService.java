package mx.pjpuebla.backend.core.service;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Rol;
import mx.pjpuebla.backend.core.entitiy.RolModuloPermiso;
import mx.pjpuebla.backend.core.entitiy.RolModuloPermisoKey;
import mx.pjpuebla.backend.core.repository.RolModuloPermisoRepository;

@Service
@AllArgsConstructor

public class RolModuloPermisoService {

    private final RolModuloPermisoRepository repo;

    public List<RolModuloPermiso> findAll() {
        return repo.findAll();
    }

    public RolModuloPermiso save(RolModuloPermiso rmp) {
        return this.repo.save(rmp);
    }

    public RolModuloPermiso findById(RolModuloPermisoKey id) {
        Optional<RolModuloPermiso> rolModuloPermiso =  this.repo.findById(id);

        if(rolModuloPermiso.isPresent()){
            return rolModuloPermiso.get();
        }

        return null;
    }

    public boolean delete(RolModuloPermiso rmp) {
        try {
            this.repo.delete(rmp);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }


    
}
