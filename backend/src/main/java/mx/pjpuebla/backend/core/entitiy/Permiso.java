package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Table(schema = "core", name = "permiso")
@Entity
@Getter
@Setter

public class Permiso {
    
    @Id
    @GeneratedValue(strategy=GenerationType.SEQUENCE, generator="PERMISO_ID_GENERATOR")	
    @SequenceGenerator(name = "PERMISO_ID_GENERATOR", sequenceName = "core.permiso_id_seq", allocationSize = 1)
    private Integer id;
    private Integer clave;
    private String descripcion;
    private boolean activo;

    public String descripcion() {
        return this.descripcion;
    }
}
