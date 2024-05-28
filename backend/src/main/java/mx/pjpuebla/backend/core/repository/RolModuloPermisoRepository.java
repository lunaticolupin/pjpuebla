package mx.pjpuebla.backend.core.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.core.entitiy.RolModuloPermiso;
import mx.pjpuebla.backend.core.entitiy.RolModuloPermisoKey;

import java.util.List;
import java.util.Optional;

public interface RolModuloPermisoRepository extends JpaRepository<RolModuloPermiso,RolModuloPermisoKey> {

    @SuppressWarnings("null")
    public Optional<RolModuloPermiso> findById(RolModuloPermisoKey id);

    public List<RolModuloPermiso> findAll();

    public List<RolModuloPermiso> findByActivo(boolean activo);

    @SuppressWarnings({"null","unchecked"})
    public RolModuloPermiso save(RolModuloPermiso rmp);
}
