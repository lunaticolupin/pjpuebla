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
    public String generarFechaSesion();

    @Query(value = "SELECT mediacion.fun_fecha_sesion(:p_fecha_comprobacion) AS resultado", nativeQuery = true)
    String validar_fecha_sesion(@Param("p_fecha_comprobacion") Date p_fecha_comprobacion);

    @Query(value = "SELECT * FROM mediacion.fun_registra_archivo(:solicitudId, :claveFormato, :usuario, :personaFirma)", nativeQuery = true)
    public boolean registrarDocumento(@Param("solicitudId") Integer solicitudId, 
        @Param("claveFormato") String claveFormato, 
        @Param("usuario") String usuario, 
        @Param("personaFirma") String personaFirma);
}
