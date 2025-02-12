package mx.pjpuebla.backend.mediacion.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import mx.pjpuebla.backend.mediacion.entitiy.Mediador;
import mx.pjpuebla.backend.mediacion.entitiy.Psicologo;

@Repository
public interface PsicologoRepository extends JpaRepository<Psicologo,Integer> {

    @SuppressWarnings("null")
    public List<Psicologo> findAll();

    @SuppressWarnings({ "null", "unchecked" })
    public Psicologo save(Psicologo p);

    public Optional<Psicologo> findTopByOrderByNumeroDesc();

    @Query(value = "SELECT * FROM mediacion.psicologo where estatus = 1", nativeQuery = true)
    public List<Psicologo> findAllByEstatus(Integer num);
}
