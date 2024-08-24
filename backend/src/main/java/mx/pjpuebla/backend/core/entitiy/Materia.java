package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.UniqueConstraint;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name="materia", schema="core", uniqueConstraints={ @UniqueConstraint(name="materia_clave_key", columnNames={"clave"})})
@Getter
@Setter

public class Materia implements Serializable{

    @Column(name="id", nullable=false)
    @Id	
	@GeneratedValue(strategy=GenerationType.SEQUENCE, generator="MATERIA_ID_GENERATOR")	
    @SequenceGenerator(name = "MATERIA_ID_GENERATOR", sequenceName = "core.materia_id_seq", allocationSize = 1)
	private Integer id;

    @Column(name="clave", nullable=false)	
	private String clave;

    @Column(name="descripcion", nullable=false)	
	private String descripcion;

    @Column(name="activo", nullable=true)	
	private Boolean activo = Boolean.valueOf(false);
}
