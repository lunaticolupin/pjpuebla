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
@Table(name="instituciones", schema = "core")
@Getter
@Setter
public class Institucion implements Serializable {
    @Column(name = "id", nullable = false)
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "INSTITUCION_ID_GENERATOR")
    @SequenceGenerator(name = "INSTITUCION_ID_GENERATOR", sequenceName = "core.instituciones_id_seq", allocationSize = 1)
    private Integer id;
    
    @Column(name = "clave", nullable = false)
    private String clave;

    @Column(name = "nombre", nullable = false)
    private String nombre;

    @Column(name = "direccion", nullable = false)
    private String direccion;

    @Column(name = "tipo", nullable = false)
    private String tipo;

    @Column(name = "activo", nullable = false)
    private Boolean activo;

    @Column(name = "contacto", nullable = false)
    private String contacto;

    
}
