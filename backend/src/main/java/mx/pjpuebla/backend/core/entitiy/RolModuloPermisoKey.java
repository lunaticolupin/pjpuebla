package mx.pjpuebla.backend.core.entitiy;
import java.io.Serializable;
import java.util.Objects;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

// import javax.persistence.*;

import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;

@Embeddable
public class RolModuloPermisoKey implements Serializable {

    @Column(name = "rol_id", nullable=false, insertable=false, updatable=false)
    private Integer rolId;

    @Column(name = "permiso_id", nullable=false, insertable=false, updatable=false )
    private Integer permisoId;

    @Column(name = "modulo_id", nullable=false, insertable=false, updatable=false )
    private Integer moduloId;


    @Override
    public boolean equals(Object o) {
        if (this == o) 
            return true;
        if (o == null || getClass() != o.getClass()) 
            return false;
        RolModuloPermisoKey that = (RolModuloPermisoKey) o;
        return Objects.equals(rolId, that.rolId) && Objects.equals(permisoId, that.permisoId) && Objects.equals(moduloId, that.moduloId);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(rolId, permisoId,moduloId);
    }

    // private Integer rolId;
    // private Integer moduloId;
    // @Column(name = "rol_id")
    // private Integer rolId;

    // @Column(name = "modulo_id", nullable=false, insertable=false, updatable=false)
    // private Integer moduloId;

    // @Column(name = "permiso_id", nullable=false, insertable=false, updatable=false)
    // private Integer permisoId;

    // @Id
    // private Integer rolId;

    // @Id 
    // private Integer moduloId;

    // @Id
    // private Integer permisoId;

    // @ManyToOne
    // @JoinColumn(name = "rolId", insertable = false, updatable = false)
    // private Rol rol;

    // @ManyToOne
    // @JoinColumn(name = "moduloId", insertable = false, updatable = false)
    // private Modulo modulo;

    // @ManyToOne
    // @JoinColumn(name = "permisoId", insertable = false, updatable = false)
    // private Permiso permiso;

    // private Integer estatus;
    
}
