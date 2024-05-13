package mx.pjpuebla.backend.mediacion.entitiy;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

@Table(schema = "mediacion", name = "tipo_cierre")
@Entity
@Getter
@Setter
public class TipoCierre {
    @Id
    private Integer id;

    @NotBlank
    private String clave;

    @NotBlank
    private String descripcion;

    @NotNull
    private Boolean activo = true;
}
