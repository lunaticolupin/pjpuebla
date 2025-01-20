package mx.pjpuebla.backend.mediacion.entitiy;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Table(schema = "mediacion", name = "expediente")
@Entity
@Getter
@Setter
public class    Expediente {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "EXPEDIENTE_ID_GENERATOR")
    @SequenceGenerator(name = "EXPEDIENTE_ID_GENERATOR", sequenceName = "mediacion.expediente_id_seq", allocationSize = 1)
    private Integer id;

    // @NotNull
	public
    // private String folio;
    Integer folio;

    @NotNull
    @JsonIgnore
    private Date fecha_registro;

    @ManyToOne
    @JoinColumn(name="mediador_id")
    private Mediador mediador;

    @OneToOne
    @JoinColumn(name = "solicitud_id")
    private Solicitud solicitud;

    private Boolean es_mediable;
    private Boolean hay_acuerdo;
    private Boolean asistencia_psicologica;
    private Boolean asistencia_juridica;
    private Integer estatus;

    // @ManyToOne
    // @JoinColumn(name = "psicologo_id")
    // private Psicologo psicologo;
}