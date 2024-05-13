package mx.pjpuebla.backend.mediacion.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.mediacion.entitiy.TipoCierre;

public interface TipoCierreRepository extends JpaRepository<TipoCierre, Integer> {
    public TipoCierre findByClave(String clave);
}
