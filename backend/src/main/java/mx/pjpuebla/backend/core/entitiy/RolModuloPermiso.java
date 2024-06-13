package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;
import java.util.List;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import jakarta.persistence.Id;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;

@Table(schema = "core", name = "rol_modulo_permiso")
@Entity
@Getter
@Setter
// @IdClass(Rol.class)

@Embeddable
public class RolModuloPermiso implements Serializable{

  @EmbeddedId
    private RolModuloPermisoKey id;
    private Integer estatus;

    @Column(name = "activo", nullable = false)
    private Boolean activo = Boolean.valueOf(true);
}