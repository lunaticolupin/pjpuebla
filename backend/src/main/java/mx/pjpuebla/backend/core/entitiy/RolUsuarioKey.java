package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
public class RolUsuarioKey implements Serializable {
    @Column(name = "usuario_id", nullable=false, insertable=false, updatable=false)
    private Integer usuarioId;

    @Column(name = "rol_id", nullable=false, insertable=false, updatable=false )
    private Integer rolId;

    @Override
    public int hashCode(){
        final int prime = 31;

        int result = 1;

        result = prime * result + ((usuarioId == null ? 0 : usuarioId.hashCode()));
        result = prime * result + ((rolId == null) ? 0 : rolId.hashCode());

        return result;
        
    }

    @Override
    public boolean equals(Object obj){
        if (this == obj)
            return true;

        if (obj == null)
            return false;

        if (getClass() != obj.getClass())
            return false;

        RolUsuarioKey tmp = ((RolUsuarioKey) obj);

        if (usuarioId == null){
            if (tmp.rolId != null){
                return false;
            }
        }else if (!usuarioId.equals(tmp.usuarioId)){
            return false;
        }

        if (rolId == null){
            if (tmp.rolId!=null){
                return false;
            }
        }else if(!rolId.equals(tmp.rolId)){
            return false;
        }

        return true;
    }

    public Integer getUsuarioId() {
        return usuarioId;
    }

    public void setUsuarioId(Integer usuarioId) {
        this.usuarioId = usuarioId;
    }

    public Integer getRolId() {
        return rolId;
    }

    public void setRolId(Integer rolId) {
        this.rolId = rolId;
    }

    
}
