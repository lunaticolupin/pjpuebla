package mx.pjpuebla.backend.core.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import mx.pjpuebla.backend.core.entitiy.Archivo;
import mx.pjpuebla.backend.mediacion.entitiy.SolicitudArchivo;
import mx.pjpuebla.backend.core.DTO.FileInfoDto;

public interface ArchivoRepository extends JpaRepository<Archivo, Long> {
        @Query(value = "select core.fun_upload_archivo(:nombre, :tipo, :data, :usuario)", nativeQuery = true)
        public Long uploadArchivo(@Param("nombre") String nombreArchivo, @Param("tipo") String tipoArchivo,
                        @Param("data") byte[] dataArchivo, @Param("usuario") String usuario);

        @SuppressWarnings("null")
        public Optional<Archivo> findById(Integer id);

        @Query("SELECT new mx.pjpuebla.backend.core.DTO.FileInfoDto(" +
                        "a.id, sa.id, f.id, f.descripcion, a.nombre, " +
                        "CASE WHEN a.nombre IS NOT NULL AND a.nombre != '' THEN true ELSE false END," +
                        "a.fechaCreacion) " +
                        "FROM SolicitudArchivo sa " +
                        "LEFT JOIN Archivo a ON a.id = sa.archivoId " +
                        "JOIN Formato f ON sa.formato = f.id " +
                        "WHERE sa.solicitudId = :solicitudId and sa.estatus = 1 and a.estatus = 1")
        List<FileInfoDto> findFileInfoBySolicitudId(@Param("solicitudId") Integer solicitudId);

}
