package mx.pjpuebla.backend.core.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.core.entitiy.Permiso;
import org.springframework.data.jpa.repository.Query; 
import java.util.List;

public interface PermisoRepository extends JpaRepository<Permiso, Integer>{

    public Permiso findById(int id);

    public List<Permiso> findByActivo(boolean status);

    @SuppressWarnings({"null","unchecked"})
    public Permiso save(Permiso p);
    
}
