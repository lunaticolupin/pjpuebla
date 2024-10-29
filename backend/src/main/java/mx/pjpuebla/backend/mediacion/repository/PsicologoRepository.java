package mx.pjpuebla.backend.mediacion.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import mx.pjpuebla.backend.mediacion.entitiy.Psicologo;

@Repository
public interface PsicologoRepository extends JpaRepository<Psicologo,Integer> {

    @SuppressWarnings("null")
    public List<Psicologo> findAll();

    @SuppressWarnings({ "null", "unchecked" })
    public Psicologo save(Psicologo p);

    public Optional<Psicologo> findTopByOrderByNumeroDesc();
}
