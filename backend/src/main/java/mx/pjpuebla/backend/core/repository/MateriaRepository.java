package mx.pjpuebla.backend.core.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.core.entitiy.Materia;

public interface MateriaRepository extends JpaRepository<Materia,Integer>{

    public Materia findById(int id);
    @SuppressWarnings({ "null", "unchecked" })
    public Materia save(Materia m);
}
