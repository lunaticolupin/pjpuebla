package mx.pjpuebla.backend.mediacion.repository;

import java.util.Date;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;

public interface SolicitudRepository extends JpaRepository<Solicitud, Integer> {
    public Solicitud findByFolio(String folio);

    @Query(value = "SELECT * FROM mediacion.foliador(:claveArea)", nativeQuery = true)
    public String generarFolio(@Param("claveArea") String claveArea);

    @Query(value = "SELECT * FROM mediacion.fun_fecha_sesion()", nativeQuery = true)
    public Date generarFechaSesion();
}
