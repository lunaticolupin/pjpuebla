package mx.pjpuebla.backend.mediacion.entitiy;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Table(schema = "mediacion", name="tipo_apertura")
@Entity
@Getter
@Setter
public class TipoApertura {
    @Id
    private Integer id;

    @NotNull
    private String clave;

    @NotNull
    private String descripcion;

    @NotNull
    private Boolean activo = true;
}
