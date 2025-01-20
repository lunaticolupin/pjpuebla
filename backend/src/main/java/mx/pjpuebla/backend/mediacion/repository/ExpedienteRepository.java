package mx.pjpuebla.backend.mediacion.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import mx.pjpuebla.backend.mediacion.entitiy.Expediente;

public interface ExpedienteRepository extends JpaRepository<Expediente, Integer> {

    @Query(value = "SELECT * FROM mediacion.expediente where solicitud_id = (:solicitudId)", nativeQuery = true)
    public Optional<Expediente> findBySolicitud(@Param("solicitudId") Integer solicitudId);
    

    @Query(value = "SELECT max(e.folio) FROM mediacion.expediente e ", nativeQuery = true)
    public Integer getFolio();

    
}

 