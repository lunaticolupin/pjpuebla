package mx.pjpuebla.backend.mediacion.entitiy;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Table(schema="mediacion", name="sesion_mediacion")
@Entity
@Getter
@Setter
public class SesionMediacion {
    
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator= "SESION_MEDIACION_ID_GENERATOR")
    @SequenceGenerator(name = "SESION_MEDIACION_ID_GENERATOR", sequenceName = "mediacion.sesion_mediacion_id_seq", allocationSize = 1)
    private Integer id;

    private Integer numero;
    private Date fecha_sesion;
    private String observaciones;
    
    @JsonIgnore
    private Date fecha_creacion;

    @JsonIgnore
    private String usuario_creo;

    @JsonIgnore
    private Date fecha_actualizacion;
    
    @JsonIgnore
    private String usuario_actualizo;

    @OneToOne
    @JoinColumn(name="expediente_id")
    private Expediente expediente;

}
