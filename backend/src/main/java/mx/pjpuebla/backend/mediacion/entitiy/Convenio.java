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


@Table(schema = "mediacion", name = "convenio")
@Entity
@Getter
@Setter
public class Convenio {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "CONVENIO_ID_GENERATOR")
    @SequenceGenerator(name = "CONVENIO_ID_GENERATOR", sequenceName = "mediacion.convenio_id_seq", allocationSize = 1)
    private Integer id;


    private double monto;
    private Integer forma_pago;
    private Boolean garantia_inmobiliaria;
    private String numero_oficio;
    private Boolean convenio_temporal;

    @OneToOne
    @JoinColumn(name = "expediente_id")
    private Solicitud solicitud;

    // @ManyToOne
    // @JoinColumn(name = "psicologo_id")
    // private Psicologo psicologo;
} 