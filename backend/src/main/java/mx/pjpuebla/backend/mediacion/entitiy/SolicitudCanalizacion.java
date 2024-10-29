package mx.pjpuebla.backend.mediacion.entitiy;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;
import mx.pjpuebla.backend.core.entitiy.Institucion;

@Entity
@Table(schema = "mediacion", name = "solicitud_canalizacion")
@Getter
@Setter
public class SolicitudCanalizacion {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator="SOLICITUD_CANALIZACION_ID_GENERATOR")
    @SequenceGenerator(name = "SOLICITUD_CANALIZACION_ID_GENERATOR", sequenceName = "mediacion.solicitud_canalizacion_id_seq", allocationSize = 1)
    private Integer id;

    @NotNull
    @ManyToOne
    @JoinColumn(name = "solicitud_id")
    @JsonBackReference
    private Solicitud  solicitud;

    @ManyToOne
    @JoinColumn(name = "institucion_id")
    private Institucion institucion;

    private String descripcion;
    private Integer estatus;

    private Date fecha_creacion = new Date();
    private Date fecha_actualizacion;

    private String usuario_creo = "TEST";


}
