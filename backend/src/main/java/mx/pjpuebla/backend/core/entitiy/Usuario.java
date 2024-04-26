package mx.pjpuebla.backend.core.entitiy;

import java.security.MessageDigest;
import java.util.Date;
//import java.util.List;
import java.util.HexFormat;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumns;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ForeignKey;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
//import jakarta.persistence.OneToMany;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import mx.pjpuebla.backend.models.UsuarioEstatus;

@Entity
@Table(name="usuario", schema="core", uniqueConstraints={ @UniqueConstraint(name="usuario_clave_key", columnNames={ "clave" }), @UniqueConstraint(name="usuario_correo_institucional_key", columnNames={ "correo_institucional" }) })
@Getter
@Setter
public class Usuario {

    @Column(name="id", nullable=false)	
	@Id	
	@GeneratedValue(strategy = GenerationType.SEQUENCE, generator="USUARIO_ID_GENERATOR")	
	@SequenceGenerator(name = "USUARIO_ID_GENERATOR", sequenceName = "core.usuario_id_seq", allocationSize = 1)
	private int id;
	
	@Column(name="clave", nullable=false, length=50)	
	private String clave;
	
	@Column(name="correo_institucional", nullable=false)	
	private String correoInstitucional;
	
	@JsonIgnore
	@Column(name="passwd", nullable=false)	
	private String passwd;

	@Transient
	private String passwdTxt;
	
	@Column(name="estatus", nullable=false)
	@Enumerated(EnumType.ORDINAL)	
	private UsuarioEstatus estatus = UsuarioEstatus.INACTIVO;
	
	@Column(name="fecha_creacion", nullable=false, length=6)	
	private Date fechaCreacion = new Date();
	
	@Column(name="usuario_creo", nullable=false, length=100)	
	private String usuarioCreo = "TEST";
	
	@Column(name="fecha_actualizacion", nullable=true, length=6)	
	private Date fechaActualizacion;
	
	@Column(name="usuario_actualizacion", nullable=true, length=100)	
	private String usuarioActualizo;

	@Column
	private Date lastLogin;

	@Transient
	private Integer personaId;
	
	//@ManyToOne(targetEntity=Persona.class, fetch=FetchType.LAZY)	
	@OneToOne
	@JoinColumns(value={ @JoinColumn(name="persona_id", referencedColumnName="id", nullable=false) })	
	private Persona persona;
	
	/* @OneToMany(mappedBy="usuario", targetEntity=mx.puebla.RolUsuario.class)	
	@org.hibernate.annotations.Cascade({org.hibernate.annotations.CascadeType.SAVE_UPDATE, org.hibernate.annotations.CascadeType.LOCK})	
	@org.hibernate.annotations.LazyCollection(org.hibernate.annotations.LazyCollectionOption.TRUE)	
	private List<Object> rolUsuario; */

	public void generarPasswd(){
		this.passwd = cifrarPassword(this.passwdTxt);
	}

	private String cifrarPassword(String passwdTxt){
		String passwdCifrado;

		try{
            byte[] bytes = passwdTxt.getBytes();
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash  = digest.digest(bytes);

            passwdCifrado = HexFormat.of().formatHex(hash);            
        }catch (Exception e){
			passwdCifrado=null;
            e.printStackTrace();
        }

		return passwdCifrado;
	}

	public boolean passwordValido(String passwdTxt){
		return this.passwd.equals(cifrarPassword(passwdTxt));
	}

	public boolean esActivo(){
		return this.estatus == UsuarioEstatus.ACTIVO;
	}

	//public boolean
}
