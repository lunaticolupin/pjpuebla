package mx.pjpuebla.backend.core.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.core.entitiy.Persona;

public interface PersonaRepository extends JpaRepository<Persona, Integer> {

    public Persona findById(int id);
    
    @SuppressWarnings({ "null", "unchecked" })
    public Persona save(Persona p);

    public Persona findByCurp(String curp);

    public Persona findByRfc(String rfc);

    public boolean existsByCurp(String curp);

    public boolean existsByRfc(String rfc);
}