package mx.pjpuebla.backend.core.DTO;

import java.sql.Timestamp;
import java.util.Date;
import java.util.UUID;
import lombok.Getter;
import lombok.Setter;


import java.time.LocalDateTime;
@Getter
@Setter
public class FileInfoDto {
    private Integer archivoId;
    private UUID solicitudArchivoId;
    private Integer formatoId;
    private String formatoDescripcion;
    private String archivoNombre;
    private Boolean existeDocumento;
    private Timestamp fechaCreacion;

    public FileInfoDto(Integer archivoId, UUID solicitudArchivoId, Integer formatoId, 
                       String formatoDescripcion, String archivoNombre, 
                       Boolean existeDocumento, Timestamp fechaCreacion) {
        this.archivoId = archivoId;
        this.solicitudArchivoId = solicitudArchivoId;
        this.formatoId = formatoId;
        this.formatoDescripcion = formatoDescripcion;
        this.archivoNombre = archivoNombre;
        this.existeDocumento = existeDocumento;
        this.fechaCreacion = fechaCreacion;
    }

    // Getters y setters


 
}
