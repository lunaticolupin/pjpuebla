package mx.pjpuebla.backend.core.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.core.entitiy.Formato;

public interface FormatoRepository extends JpaRepository<Formato, Integer> {
    
    public List<Formato> findByNombreReporte(String nombre);
}
