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


@Table(schema = "mediacion", name = "beneficiario")
@Entity
@Getter
@Setter
public class Beneficiario {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "BENEFICIARIO_ID_GENERATOR")
    @SequenceGenerator(name = "BENEFICIARIO_ID_GENERATOR", sequenceName = "mediacion.beneficiario_id_seq", allocationSize = 1)
    private Integer id;

    private String sexo;
    private String edad;
    

    @OneToOne
    @JoinColumn(name = "expediente_id")
    private Expediente expediente;

    // @ManyToOne
    // @JoinColumn(name = "psicologo_id")
    // private Psicologo psicologo;
} 