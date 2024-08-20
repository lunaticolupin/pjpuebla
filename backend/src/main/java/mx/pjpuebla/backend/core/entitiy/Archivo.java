package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;
import java.util.Date;

import jakarta.persistence.Column;

// import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "archivo", schema = "core")
@Getter
@Setter
public class Archivo implements Serializable {

    // @Column(name = "id", nullable = false)
    // @Id
    // @GeneratedValue(strategy = GenerationType.IDENTITY)

    @Column(name = "id", nullable=false)
    @Id	
	@GeneratedValue(strategy=GenerationType.SEQUENCE, generator="ARCHIVO_ID_GENERATOR")	
    @SequenceGenerator(name = "ARCHIVO_ID_GENERATOR", sequenceName = "core.archivo_id_seq", allocationSize = 1)
    public Integer id;

    @Column(name = "nombre", nullable = false)
    public String nombre;

    @Column(name = "tipo", nullable = true)
    private String tipo;
    
    @Column(name = "fecha_creacion", nullable = true)
    private Date fecha_creacion = new Date();
    
    @Column(name = "usuario_creo", nullable = true)
    private String usuario_creo;
    
    
    // @JsonIgnore
    // private Long id;
    // // private String nombre;
    // private String usuario_Creo;

    // @JsonIgnore
    // private byte[] data;
    // private Date fechaCreacion;
    // private String firma;
}
