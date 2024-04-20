package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;
import java.util.Date;

import com.fasterxml.jackson.annotation.JsonIgnore;

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
@Table(name="persona", schema="core", uniqueConstraints={ @UniqueConstraint(name="persona_curp_key", columnNames={ "curp" }), @UniqueConstraint(name="persona_email_key", columnNames={ "email" }), @UniqueConstraint(name="persona_rfc_key", columnNames={ "rfc" }) })
@Getter
@Setter
public class Persona implements Serializable {
    @Column(name="id", nullable=false)	
	@Id	
	@GeneratedValue(strategy=GenerationType.SEQUENCE, generator="PERSONA_ID_GENERATOR")	
	//@org.hibernate.annotations.GenericGenerator(name="MX_PUEBLA_PERSONA_ID_GENERATOR", strategy="sequence", parameters={ @org.hibernate.annotations.Parameter(name="sequence", value="core.persona_id_seq") })
    @SequenceGenerator(name = "PERSONA_ID_GENERATOR", sequenceName = "core.persona_id_seq", allocationSize = 1)
	private Integer id;
	
	@Column(name="nombre", nullable=false)	
	private String nombre;
	
	@Column(name="apellido_paterno", nullable=true)	
	private String apellidoPaterno;
	
	@Column(name="apellido_materno", nullable=true)	
	private String apellidoMaterno;
	
	@Column(name="curp", nullable=true, length=20)	
	private String curp;
	
	@Column(name="rfc", nullable=true)	
	private String rfc;
	
	@Column(name="sexo", nullable=true, length=1)	
	private String sexo;
	
	@Column(name="email", nullable=true)	
	private String email;
	
	@Column(name="telefono", nullable=true, length=15)	
	private String telefono;
	
	@Column(name="calle", nullable=true)	
	private String calle;
	
	@Column(name="cp", nullable=true, length=5)	
	private String cp;
	
	@Column(name="persona_moral", nullable=true)	
	private Boolean personaMoral = Boolean.valueOf(false);
	
	@Column(name="estado_civil", nullable=true, length=1)	
	private String estadoCivil;
	
	@JsonIgnore
	@Column(name="fecha_creacion", nullable=false, length=6)	
	private Date fechaCreacion = new Date();
	
	@JsonIgnore
	@Column(name="usuario_creo", nullable=false, length=50)	
	private String usuarioCreo;
	
	@JsonIgnore
	@Column(name="fecha_actualizacion", nullable=true, length=6)	
	private Date fechaActualizacion;
	
	@JsonIgnore
	@Column(name="usuario_actualizo", nullable=true, length=50)	
	private String usuarioActualizo;
	
	@Column(name="hablante_lengua_distinta", nullable=false)	
	private boolean hablanteLenguaDistinta = false;
}
