package mx.pjpuebla.backend.mediacion.entitiy;

import java.util.Date;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(schema = "mediacion", name = "solicitud_archivo")
@Getter
@Setter
public class SolicitudArchivo {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    private Long solicitudId;
    private Long archivoId;
    private Long formatoId;

    private int estatus;

    private Date fechaCreacion=new Date();
    private Date fechaActualizacion;

    private String usuarioCreo;
    private String usuarioActualizo;

    private String personaFirma;
}
