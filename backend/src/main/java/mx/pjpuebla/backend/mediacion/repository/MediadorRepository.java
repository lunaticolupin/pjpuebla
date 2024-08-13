package mx.pjpuebla.backend.mediacion.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.mediacion.entitiy.Mediador;

public interface MediadorRepository extends JpaRepository<Mediador,Integer> {
    
    @SuppressWarnings("null")
    public List<Mediador> findAll();

    @SuppressWarnings({ "null", "unchecked" })
    public Mediador save(Mediador m);

}
