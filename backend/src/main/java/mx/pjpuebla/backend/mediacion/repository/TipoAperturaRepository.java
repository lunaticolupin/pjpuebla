package mx.pjpuebla.backend.mediacion.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import mx.pjpuebla.backend.mediacion.entitiy.TipoApertura;

public interface TipoAperturaRepository extends JpaRepository<TipoApertura, Integer> {
    public TipoApertura findByClave(String clave);
}
