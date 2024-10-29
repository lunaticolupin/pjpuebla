package mx.pjpuebla.backend.mediacion.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.mediacion.entitiy.Expediente;

public interface ExpedienteRepository extends JpaRepository<Expediente, Integer> {
    
}
