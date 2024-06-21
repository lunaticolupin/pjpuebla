package mx.pjpuebla.backend.core.entitiy;

import java.io.Serializable;
import java.util.List;
import java.util.Set;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinColumns;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.OneToMany;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Table(schema = "core", name = "rol")
@Entity
@Getter
@Setter
public class Rol implements Serializable {

    @Id
    @GeneratedValue(strategy=GenerationType.SEQUENCE, generator="ROL_ID_GENERATOR")	
    @SequenceGenerator(name = "ROL_ID_GENERATOR", sequenceName = "core.rol_id_seq", allocationSize = 1)
    private Integer id;

    private String clave;

    private String descripcion;

    @Column(name = "activo", nullable = false)
    private Boolean activo = Boolean.valueOf(true);

    @OneToMany // 1 :: N Modulos
	@JoinTable(schema = "core", name = "rol_modulo_permiso", joinColumns = @JoinColumn(name="rol_id"), inverseJoinColumns = @JoinColumn(name="modulo_id"))
	private List<Modulo> modulos;    
}
