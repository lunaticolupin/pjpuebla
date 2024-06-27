package mx.pjpuebla.backend.core.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import mx.pjpuebla.backend.core.entitiy.Archivo;

public interface ArchivoRepository extends JpaRepository<Archivo, Long> {
    @Query(value="select core.fun_upload_archivo(:nombre, :tipo, :data, :usuario)", nativeQuery = true)
    public Long uploadArchivo(@Param("nombre") String nombreArchivo, @Param("tipo") String tipoArchivo, @Param("data") byte[] dataArchivo, @Param("usuario") String usuario);

    @SuppressWarnings("null")
    public Optional<Archivo> findById(Long id);
}
