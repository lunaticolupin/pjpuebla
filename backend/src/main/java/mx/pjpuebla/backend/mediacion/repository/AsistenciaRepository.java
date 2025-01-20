package mx.pjpuebla.backend.mediacion.repository;

import java.util.Date;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import mx.pjpuebla.backend.mediacion.entitiy.Asistencia;

public interface AsistenciaRepository extends JpaRepository<Asistencia, Integer> {
    
    public List<Asistencia> findAllBySolicitudIdOrderByFechaAsistenciaAsc(Integer id);

    public Integer countBySolicitudId(Integer id);

    @Query(value = "SELECT * FROM mediacion.fun_fecha_sesion()", nativeQuery = true)
    public String generarFechaSesion();

    @Query(value = "SELECT mediacion.fun_fecha_sesion(:p_fecha_comprobacion) AS resultado", nativeQuery = true)
    String validar_fecha_sesion(@Param("p_fecha_comprobacion") Date p_fecha_comprobacion);

    
}
