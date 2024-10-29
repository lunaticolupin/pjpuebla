package mx.pjpuebla.backend.mediacion.repository;
import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.entitiy.SolicitudCanalizacion;

public interface SolicitudCanalizacionRepository extends JpaRepository<SolicitudCanalizacion, Integer> {



    
}
