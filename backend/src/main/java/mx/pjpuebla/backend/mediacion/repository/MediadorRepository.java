package mx.pjpuebla.backend.mediacion.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import mx.pjpuebla.backend.mediacion.entitiy.Mediador;

public interface MediadorRepository extends JpaRepository<Mediador,Integer> {
    
    @SuppressWarnings("null")
    public List<Mediador> findAll();

    @SuppressWarnings({ "null", "unchecked" })
    public Mediador save(Mediador m);

    @Query(value = "SELECT * FROM mediacion.mediador where estatus = 1 order by orden asc", nativeQuery = true)
    public List<Mediador> findAllByEstatus(Integer num);

    public Optional<Mediador> findTopByOrderByNumeroDesc();


    // @Query(value = "SELECT * FROM mediacion.medidador where orden = 1 order by orden asc", nativeQuery = true)
    // public String generarFechaSesion();

}
