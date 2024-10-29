package mx.pjpuebla.backend.mediacion.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.mediacion.entitiy.SesionMediacion;

public interface SesionMediacionRepository extends JpaRepository<SesionMediacion, Integer> {
    
}
