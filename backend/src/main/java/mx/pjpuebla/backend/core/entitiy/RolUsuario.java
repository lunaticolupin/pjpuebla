package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;
import java.util.Date;

import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import lombok.Getter;
import lombok.Setter;

@Table(schema = "core", name = "rol_usuario")
@Entity
@Getter
@Setter
public class RolUsuario implements Serializable {
    @EmbeddedId
    private RolUsuarioKey id;

    @ManyToOne
    @JoinColumn(name="rol_id")
    Rol rol;

    private int estatus;
    private Date fechaCreacion = new Date();
    private String usuarioCreo ="TEST";
    private Date fechaActualizacion;
    private String usuarioActualizo;
}
