package mx.pjpuebla.backend.mediacion.entitiy;

import java.io.Serializable;
import java.util.Date;

import com.fasterxml.jackson.annotation.JsonIgnore;

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

@Entity
@Table(name = "mediador", schema="mediacion")
@Getter
@Setter
public class Mediador implements Serializable {

    @Column(name="id", nullable=false)
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator="MEDIADOR_ID_GENERATOR")
    @SequenceGenerator(name = "MEDIADOR_ID_GENERATOR", sequenceName = "mediacion.mediador_id_seq", allocationSize = 1)
    private Integer id;

    @Column(name="numero",nullable = false)
    private Integer numero;

    @Column(name = "certificado", nullable = false)
    private String certificado;

    @Column(name = "estatus", nullable = false)
    private Integer estatus;

    @NotNull
    @ManyToOne
    @JoinColumn(name = "supervisado_por",  referencedColumnName = "id")
    private Persona supervisadoPor;

    @NotNull
    @ManyToOne
    @JoinColumn(name = "usuario_id",  referencedColumnName = "id")
    private Persona usuario;

    @JsonIgnore
    @Column(name = "fecha_registro", nullable = false, length = 6)
    private Date fechaCreacion = new Date();

    @JsonIgnore
    @Column(name="usuario_registro", nullable = false)
    private String usuarioRegistro;

    @JsonIgnore
	@Column(name="fecha_actualizacion", nullable=true, length=6)	
	private Date fechaActualizacion;
    
    @JsonIgnore
	@Column(name="usuario_actualizo", nullable=true, length=50)	
	private String usuarioActualizo;

}
