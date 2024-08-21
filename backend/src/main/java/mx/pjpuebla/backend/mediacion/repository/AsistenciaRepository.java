package mx.pjpuebla.backend.mediacion.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import mx.pjpuebla.backend.mediacion.entitiy.Asistencia;

public interface AsistenciaRepository extends JpaRepository<Asistencia, Integer> {
    
    public List<Asistencia> findAllBySolicitudId(Integer id);

    @Query(value = "SELECT * FROM mediacion.fun_fecha_sesion()", nativeQuery = true)
    public String generarFechaSesion();
    
}
