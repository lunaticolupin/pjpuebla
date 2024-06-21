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

    @Column(name = "rol_id")
    private Integer rolId;

    @Column(name = "permiso_id")
    private Integer permisoId;

    @Column(name = "modulo_id")
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

    public Integer getRolId() {
        return rolId;
    }
    
    public void setRolId(Integer rolId) {
        this.rolId = rolId;
    }

    public Integer getPermisoId() {
        return permisoId;
    }
    
    public void setPermisoId(Integer permisoId) {
        this.permisoId = permisoId;
    }

    public Integer getModuloId() {
        return moduloId;
    }

    public void setModuloId(Integer moduloId) {
        this.moduloId = moduloId;
    }

}
