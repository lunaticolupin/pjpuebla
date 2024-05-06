package mx.pjpuebla.backend.core.entitiy;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Table(schema = "core", name = "rol")
@Entity
@Getter
@Setter
public class Rol {

    @Id
    private Integer id;

    private String clave;

    private String descripcion;

    private boolean activo;
}
