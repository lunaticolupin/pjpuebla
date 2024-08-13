package mx.pjpuebla.backend.mediacion.entitiy;

import jakarta.persistence.Column;
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
import mx.pjpuebla.backend.core.entitiy.Persona;

@Table(schema="mediacion", name = "psicologo")
@Entity
@Getter
@Setter
public class Psicologo {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "PSICOLOGO_ID_GENERATOR")
    @SequenceGenerator(name="PSICOLOGO_ID_GENERATOR", sequenceName = "mediacion.psicologo_id_seq", allocationSize = 1)
    private Integer id;

    @Column(name = "numero", nullable = false)
    private Integer numero;

    @Column(name = "estatus", nullable = false)
    private Integer estatus;


    @NotNull
    @ManyToOne
    @JoinColumn(name = "usuario_id", referencedColumnName = "id")
    private Persona usuario;

}
