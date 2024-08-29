package mx.pjpuebla.backend.mediacion.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import mx.pjpuebla.backend.mediacion.entitiy.SolicitudArchivo;

public interface SolicitudArchivoRepository extends JpaRepository<SolicitudArchivo, UUID> {

    // @Query(value="select core.fun_upload_archivo(:nombre, :tipo, :data, :usuario)", nativeQuery = true)
    // public Long uploadArchivo(@Param("nombre") String nombreArchivo, @Param("tipo") String tipoArchivo, @Param("data") byte[] dataArchivo, @Param("usuario") String usuario);

    @SuppressWarnings("null")
    public Optional<SolicitudArchivo> findById(UUID id);

    public SolicitudArchivo findBySolicitudId(Integer id);

    public SolicitudArchivo findBySolicitudIdAndArchivoId(Integer solicitud_id, Integer archivo_id);

    public SolicitudArchivo findBySolicitudIdAndFormatoAndEstatus(Integer solicitud_id, Integer formato_id, Integer estatus);
}
