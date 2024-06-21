package mx.pjpuebla.backend.core.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.core.entitiy.Rol;
import org.springframework.data.jpa.repository.Query; 
import java.util.List;


public interface RolRepository extends JpaRepository<Rol, Integer> {
    
    public Rol findById(int id);

    public List<Rol> findByActivo(boolean status);
    
    @SuppressWarnings({"null","unchecked"})
    public Rol save(Rol r);

    // @Query( 
    //     nativeQuery = true, 
    //     value 
    //     = "SELECT * FROM core.rol WHERE activo = true") 
    //    List<Rol> findByActivo(); 
    
}
