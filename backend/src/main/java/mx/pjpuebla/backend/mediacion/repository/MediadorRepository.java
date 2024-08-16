package mx.pjpuebla.backend.mediacion.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.mediacion.entitiy.Mediador;

public interface MediadorRepository extends JpaRepository<Mediador,Integer> {
    
    @SuppressWarnings("null")
    public List<Mediador> findAll();

    @SuppressWarnings({ "null", "unchecked" })
    public Mediador save(Mediador m);

    public List<Mediador> findAllByEstatus(Integer num);

    public Optional<Mediador> findTopByOrderByNumeroDesc();

}
