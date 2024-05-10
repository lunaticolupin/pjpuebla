package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;

import com.fasterxml.jackson.annotation.JsonProperty;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Table(schema = "core", name = "materia")
@Entity
@Getter
@Setter
public class Materia implements Serializable {
    @Id
    private Integer id;
    private String clave;
    private String descripcion;
    private boolean activo = true;

    /*@JsonProperty
    public Integer value (){
        return id;
    }*/
}
