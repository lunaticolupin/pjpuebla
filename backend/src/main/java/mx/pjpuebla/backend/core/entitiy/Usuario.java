package mx.pjpuebla.backend.core.entitiy;

import java.util.Date;
//import java.util.List;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumns;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.ManyToOne;
//import jakarta.persistence.OneToMany;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;
import jakarta.persistence.Table;

@Entity
@Table(name="usuario", schema="core", uniqueConstraints={ @UniqueConstraint(name="usuario_clave_key", columnNames={ "clave" }), @UniqueConstraint(name="usuario_correo_institucional_key", columnNames={ "correo_institucional" }) })
@Getter
@Setter
public class Usuario {
    @Column(name="id", nullable=false)	
	@Id	
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator="USUARIO_ID_GENERATOR")	
	//@org.hibernate.annotations.GenericGenerator(name="MX_PUEBLA_USUARIO_ID_GENERATOR", strategy="sequence", parameters={ @org.hibernate.annotations.Parameter(name="sequence", value="core.usuario_id_seq") })	
	@SequenceGenerator(name = "USUARIO_ID_GENERATOR", sequenceName = "core.usuario_id_seq", allocationSize = 1)
	private int id;
	
	@Column(name="clave", nullable=false, length=50)	
	private String clave;
	
	@Column(name="correo_institucional", nullable=false)	
	private String correoInstitucional;
	
	@Column(name="passwd", nullable=false)	
	private String passwd;
	
	@Column(name="estatus", nullable=false)	
	private short estatus = 0;
	
	@Column(name="fecha_creacion", nullable=false, length=6)	
	private Date fechaCreacion = new Date();
	
	@Column(name="usuario_creo", nullable=false, length=100)	
	private String usuarioCreo;
	
	@Column(name="fecha_actualizacion", nullable=true, length=6)	
	private Date fechaActualizacion;
	
	@Column(name="usuario_actualizacion", nullable=true, length=100)	
	private String usuarioActualizo;
	
	@ManyToOne(targetEntity=Persona.class, fetch=FetchType.LAZY)	
	@JoinColumns(value={ @JoinColumn(name="persona_id", referencedColumnName="id", nullable=false) }, foreignKey=@ForeignKey(name="usuario_persona_id_fkey"))	
	private Persona persona;
	
	/* @OneToMany(mappedBy="usuario", targetEntity=mx.puebla.RolUsuario.class)	
	@org.hibernate.annotations.Cascade({org.hibernate.annotations.CascadeType.SAVE_UPDATE, org.hibernate.annotations.CascadeType.LOCK})	
	@org.hibernate.annotations.LazyCollection(org.hibernate.annotations.LazyCollectionOption.TRUE)	
	private List<Object> rolUsuario; */
}
