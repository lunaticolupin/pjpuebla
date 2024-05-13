package mx.pjpuebla.backend.mediacion.entitiy;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonFormat;

import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import lombok.Getter;
import lombok.Setter;

import mx.pjpuebla.backend.core.entitiy.Materia;
import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.models.SolicitudMediacionEstatus;

@Table(schema="mediacion", name = "solicitud")
@Entity
@Getter
@Setter
public class Solicitud {
    @Id
    @GeneratedValue(strategy=GenerationType.SEQUENCE, generator="SOLICITUD_ID_GENERATOR")	
    @SequenceGenerator(name = "SOLICITUD_ID_GENERATOR", sequenceName = "mediacion.solicitud_id_seq", allocationSize = 1)
    private Integer id;

    @NotBlank
    private String folio;

    @NotNull
    @JsonFormat(pattern = "yyyy-MM-dd")
    private Date fechaSolicitud = new Date();

    //@JsonFormat(pattern = "dd/MM/yyyy")
    private Date fechaSesion;

    private Boolean esMediable = true;

    private Boolean canalizado = false;

    @NotBlank
    private String descripcionConflicto;

    private Date fechaCreacion = new Date();

    private String usuarioCreo;

    private Date fechaActualizacion;

    private String usuarioActualizo;

    @NotNull
    @ManyToOne
    @JoinColumn(name = "usuario_persona_id")
    private Persona usuarioPersona;

    @NotNull
    @ManyToOne
    @JoinColumn(name = "invitado_persona_id")
    private Persona invitadoPersona;

    @NotNull
    @ManyToOne
    @JoinColumn(name = "materia_id")
    private Materia materia;
    
    @OneToOne
    @JoinColumn(name = "asesoria_id", referencedColumnName = "id")
    private Asesoria asesoria;

    @NotNull
    @ManyToOne
    @JoinColumn(name = "tipo_apertura_id")
    private TipoApertura tipoApertura;

    @ManyToOne
    @JoinColumn(name = "tipo_cierre_id")
    private TipoCierre tipoCierre; 

    @Enumerated(EnumType.ORDINAL)
    @JsonFormat(shape = JsonFormat.Shape.NUMBER)
    private SolicitudMediacionEstatus estatus=SolicitudMediacionEstatus.RECEPCION;

    @Transient
    private String seguimiento="Recepción";
}
