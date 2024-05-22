package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;
import java.util.List;
import java.util.Objects;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.MapsId;

@Table(schema = "core", name = "rol_modulo_permiso")
@Entity
@Getter
@Setter
// @IdClass(Rol.class)

@Embeddable
public class RolModuloPermiso implements Serializable{

  @EmbeddedId
    private RolModuloPermisoKey id;
    

    // @ManyToOne
    // @JoinColumn(name = "rol_id", insertable = false, updatable = false)
    // @JoinColumn(name = "rol_id", insertable = false, updatable = false)
    // private Rol rol;

    // @ManyToOne
    // @JoinColumn(name = "modulo_id", insertable = false, updatable = false)
    // private  modulo;

    // @ManyToOne
    // @JoinColumn(name = "permiso_id", insertable = false, updatable = false)
    // private Permiso permiso;

    private Integer estatus;

    // @Id
    // private Integer rolId;

    // @Id 
    // private Integer moduloId;

    // @Id
    // private Integer permisoId;
    
    // private Integer rolId;
    // private Integer moduloId;
    // private Integer PermisoId;
    // private Integer estatus;
	// public Object findAll() {
	// 	// TODO Auto-generated method stub
	// 	throw new UnsupportedOperationException("Unimplemented method 'findAll'");
	// }
    
}