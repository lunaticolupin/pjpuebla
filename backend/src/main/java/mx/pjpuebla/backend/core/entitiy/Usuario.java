package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;
import java.security.MessageDigest;
import java.util.Date;
import java.util.HexFormat;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumns;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.UniqueConstraint;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;

import lombok.Getter;
import lombok.Setter;

import mx.pjpuebla.backend.models.UsuarioEstatus;

@Entity
@Table(name="usuario", schema="core", uniqueConstraints={ @UniqueConstraint(name="usuario_clave_key", columnNames={ "clave" }), @UniqueConstraint(name="usuario_correo_institucional_key", columnNames={ "correo_institucional" }) })
@Getter
@Setter
public class Usuario implements Serializable{

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
	
	@OneToOne
	@JoinColumns(value={ @JoinColumn(name="persona_id", referencedColumnName="id", nullable=false) })
	@JsonIgnore	
	private Persona persona;

	@ManyToMany
	@JoinTable(schema = "core", name = "rol_usuario", joinColumns = @JoinColumn(name="usuario_id"), inverseJoinColumns = @JoinColumn(name="rol_id"))
	private List<Rol> rolUsuario;

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

	@JsonProperty
	public String nombreCompleto (){
		if (this.persona != null){
			return this.persona.fullName();
		}

		return "";
	}

	public String getRoles(){
		
		String rolesTmp = "";

		for (Rol tmp : rolUsuario) {
			rolesTmp += tmp.getClave() + ",";
		}

		if (rolesTmp.length()>0){
			rolesTmp = rolesTmp.substring(0, rolesTmp.length()-1);
		}
		
		return rolesTmp;

	}
}
