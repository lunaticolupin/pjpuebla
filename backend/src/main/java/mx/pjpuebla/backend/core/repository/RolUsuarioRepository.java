package mx.pjpuebla.backend.core.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.core.entitiy.RolUsuario;
import mx.pjpuebla.backend.core.entitiy.RolUsuarioKey;
import java.util.List;
import java.util.Optional;

public interface RolUsuarioRepository extends JpaRepository<RolUsuario, RolUsuarioKey> {

    @SuppressWarnings("null")
    public Optional<RolUsuario> findById(RolUsuarioKey id);

    @SuppressWarnings({"null","unchecked"})
    public RolUsuario save(RolUsuario ru);

    @SuppressWarnings("null")
    public List<RolUsuario> findAll();

    // public RolUsuario delete(RolUsuarioKey ru);

    @SuppressWarnings("null")
    public boolean existsById(RolUsuarioKey id);

}
