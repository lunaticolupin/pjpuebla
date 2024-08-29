package mx.pjpuebla.backend.core.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.core.entitiy.Formato;

public interface FormatoRepository extends JpaRepository<Formato, Integer> {
    
    public List<Formato> findByNombreReporte(String nombre);
    
    @SuppressWarnings("null")
    public Optional<Formato> findById(Integer id);
}
