package mx.pjpuebla.backend.mediacion.service;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.mediacion.entitiy.Asistencia;
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.repository.AsistenciaRepository;

@Service
@AllArgsConstructor
public class AsistenciaService {
    private final AsistenciaRepository repositorio;
    private SolicitudService solService;
    private final ObjectMapper objectMapper = new ObjectMapper();


    public Asistencia save(Asistencia asistencia) {
        return this.repositorio.save(asistencia);
    }

    public List<Asistencia> findAllBySolicitudId(Integer id) {
        List<Asistencia> asistencias = this.repositorio.findAllBySolicitudId(id);
        return asistencias;
    }

    /**
     * Determina el estado de agendabilidad basado en las fechas de asistencia y el
     * número de registros asociados con una solicitud.
     *
     * @param solicitud_id El ID de la solicitud para la cual se desea determinar el
     *                     estado de agendabilidad.
     * @return Un entero que representa el estado de agendabilidad:
     *         - `2` si hay exactamente dos asistencias asociadas con la solicitud.
     *         - `3` si existe al menos una asistencia con una fecha menor o igual a
     *         la fecha actual.
     *         - `1` si ninguna de las condiciones anteriores se cumple.
     */
    public Integer esAgendable(Integer solicitud_id) {
       
        List<Asistencia> asistencias = findAllBySolicitudId(solicitud_id);
        Boolean fecha_activa;
        Date today = new Date();

        if (asistencias.size() == 2) {
            return 2;
        }

        fecha_activa = asistencias.stream()
                .anyMatch(asistencia -> asistencia.getFecha_asistencia().compareTo(today) <= 0);

        if (fecha_activa) {
            return 3;
        }

        return 1;
    }

    public Asistencia obtenerFecha(Integer solicitud_id){
        try {

            Solicitud solicitud = solService.findById(solicitud_id);
            
            if(solicitud != null && solicitud.getEsMediable() == 1){
                String jsonResult = this.repositorio.generarFechaSesion();
                JsonNode jsonNode = objectMapper.readTree(jsonResult);
                
                // Define el formato de la cadena
                SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                String fs = jsonNode.path("fecha").asText();
                Date fechaSesion = formatter.parse(fs); 
                

                solicitud.setFechaSesion(fechaSesion);
                solService.save(solicitud);

                Asistencia asistencia = new Asistencia();
                asistencia.setSolicitud(solicitud);
                asistencia.setFecha_asistencia(fechaSesion);
                ;

                return this.repositorio.save(asistencia);   
            }
        }catch(Exception e){
            System.out.println(e);
        }

        return null;

    }
}
