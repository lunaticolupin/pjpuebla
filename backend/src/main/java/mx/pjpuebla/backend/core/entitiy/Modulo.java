package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "modulo", schema = "core", uniqueConstraints = {@UniqueConstraint(name="modulo_clave_key",columnNames = {"clave"})})
@Getter
@Setter

public class Modulo implements Serializable {
    @Column(name = "id", nullable = false)
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "MODULO_ID_GENERATOR")
    @SequenceGenerator(name = "MODULO_ID_GENERATOR", sequenceName = "core.modulo_id_seq", allocationSize = 1)
    private Integer id;

    @Column(name = "clave", nullable = false, length = 20)
    private String clave;

    @Column(name = "descripcion", nullable = true)
    private String descripcion;

    @Column(name = "estatus", nullable = true)
    private Integer estatus;

    @Column(name = "modulo_padre", nullable = true )
    private Integer modulo_padre;

}