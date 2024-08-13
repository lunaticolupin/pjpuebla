package mx.pjpuebla.backend.core.repository;
import mx.pjpuebla.backend.core.entitiy.Institucion;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

public interface InstitucionRepository extends JpaRepository<Institucion, Integer> {
    
    public List<Institucion> findAllByActivo(Boolean activo);
}
