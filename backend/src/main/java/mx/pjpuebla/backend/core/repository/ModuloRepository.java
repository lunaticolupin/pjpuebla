package mx.pjpuebla.backend.core.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.core.entitiy.Modulo;

public interface ModuloRepository extends JpaRepository<Modulo,Integer> {
    public Modulo findById(int id);
    @SuppressWarnings({"null", "unchecked"})
    public Modulo save(Modulo m);

    
}
