package mx.pjpuebla.backend.mediacion.entitiy;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;
import jakarta.persistence.Transient;
import lombok.Getter;
import lombok.Setter;

@Table(schema = "mediacion", name = "asistencia")
@Entity
@Getter
@Setter
public class Asistencia {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "ASISTENCIA_ID_GENERATOR")
    @SequenceGenerator(name = "ASISTENCIA_ID_GENERATOR", sequenceName = "mediacion.asistencia_id_seq", allocationSize = 1)
    private Integer id;

    @NotNull
    @ManyToOne
    @JoinColumn(name = "solicitud_id")
    @JsonBackReference
    private Solicitud  solicitud;

    @Column(name = "fecha_asistencia")
    private Date fechaAsistencia;
    private Boolean asiste_usuario;
    private Boolean asiste_invitado;
    private Integer tipo;
    private Boolean acepta_usuario;
    private Boolean acepta_invitado;
    @NotNull
    private Integer estatus = 1;

    @JsonIgnore
    private Date fecha_registro = new Date();
    @JsonIgnore
    private String usuario_creo = "TEST";
    @JsonIgnore
    private Date fecha_actualizacion;
    @JsonIgnore
    private String usuario_actualizo = "TEST";

    @OneToOne
    @JoinColumn(name = "sesion_mediacion_id")
    private SesionMediacion sesionMediacion;


}
