package mx.pjpuebla.backend.mediacion.entitiy;

import java.util.Date;

import org.json.JSONArray;
import org.json.JSONObject;

import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;
import mx.pjpuebla.backend.core.entitiy.Archivo;
import mx.pjpuebla.backend.core.entitiy.Formato;

@Entity
@Table(schema = "mediacion", name = "solicitud_archivo")
@Getter
@Setter
public class SolicitudArchivo {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private String id;

    @JsonIgnore
    private Long solicitudId;

    @OneToOne
    @JoinColumn(name = "archivo_id")
    private Archivo archivo;

    @ManyToOne
    private Formato formato;

    private int estatus;

    private Date fechaCreacion=new Date();
    private Date fechaActualizacion;

    private String usuarioCreo;
    private String usuarioActualizo;

    private String personaFirma;

    public Object getArchivo(){
        if (archivo==null){
            return archivo;
        }
 
        JSONObject object = new JSONObject();

        object.put("id", archivo.getId());  
        object.put("nombre", archivo.getNombre());

        return object.toMap();
    }
}
