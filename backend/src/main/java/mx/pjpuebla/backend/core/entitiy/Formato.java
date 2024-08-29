package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(schema = "core", name = "formato")
@Getter
@Setter
public class Formato implements Serializable {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private String clave;
    private String descripcion;
    private String version;
    private boolean activo;

    @Column(name="nombre_reporte")
    private String nombreReporte;

    @JsonProperty("esAcuse")
    public boolean getEsAcuse() {
        return descripcion != null && descripcion.toUpperCase().contains("ACUSE");
    }
}
