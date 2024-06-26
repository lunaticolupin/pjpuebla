package mx.pjpuebla.backend.mediacion.entitiy;

import java.util.Date;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;

import lombok.Getter;
import lombok.Setter;

import mx.pjpuebla.backend.core.entitiy.Materia;
import mx.pjpuebla.backend.core.entitiy.Persona;

@Table(schema = "mediacion", name="asesoria")
@Entity
@Getter
@Setter
public class Asesoria {
    @Id
    private Integer id;

    @NotNull
    private Date fecha = new Date();

    @NotNull
    private String usuarioCreo;

    @NotNull
    private Persona personaAtendida;

    @NotNull
    private Materia materia;

    @OneToOne(mappedBy = "asesoria")
    private Solicitud solicitud;

}