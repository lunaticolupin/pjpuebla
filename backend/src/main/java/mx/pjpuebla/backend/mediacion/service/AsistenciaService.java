package mx.pjpuebla.backend.mediacion.service;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.mediacion.entitiy.Asistencia;
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.repository.AsistenciaRepository;
import mx.pjpuebla.backend.response.GenericResponse;

@Service
@AllArgsConstructor
public class AsistenciaService {
    private final AsistenciaRepository repositorio;
    private SolicitudService solService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public Asistencia save(Asistencia asistencia) {
        return this.repositorio.save(asistencia);
    }

    public Integer numAsistencia(Integer solicitudId){
        return repositorio.countBySolicitudId(solicitudId);
    }

    public List<Asistencia> findAllBySolicitudIdOrderByFechaAsistenciaAsc(Integer id) {
        List<Asistencia> asistencias = this.repositorio.findAllBySolicitudIdOrderByFechaAsistenciaAsc(id);
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
        //Declaramos variables a utilizar
        List<Asistencia> asistencias = findAllBySolicitudIdOrderByFechaAsistenciaAsc(solicitud_id);

        // Mostrar las fechas para depuración
        for (Asistencia asistencia2 : asistencias) {
            if(Boolean.TRUE.equals(asistencia2.getAcepta_usuario()) && 
                Boolean.TRUE.equals(asistencia2.getAcepta_invitado())){
                return 2;
            }   
        }

        // Si hay dos asistencias, devuelve 2
        if (asistencias.size() == 2) {
            return 3;
        }

        // Verifica si alguna asistencia tiene una fecha igual o mayor a hoy tomando en consideracion el tiepo
        boolean fecha_activa = asistencias.stream()
                .anyMatch(asistencia -> asistencia.getFechaAsistencia().toInstant()
                        .atZone(ZoneId.systemDefault()).compareTo(ZonedDateTime.now()) >= 0);

        if (fecha_activa) {
            return 4;
        }

        return 1;
    }

    public Asistencia obtenerFecha(Integer solicitud_id) {
        try {

            Solicitud solicitud = solService.findById(solicitud_id);

            if (solicitud != null && solicitud.getEsMediable() == 1) {
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
                asistencia.setTipo( numAsistencia(solicitud_id) + 1);
                asistencia.setFechaAsistencia(fechaSesion);
                asistencia.setFecha_actualizacion(new Date());   

                return this.repositorio.save(asistencia);
            }
        } catch (Exception e) {
            System.out.println(e);
        }

        return null;

    }

    public ResponseEntity<GenericResponse> actualizarAsistencia(Asistencia asistencia, Integer solicitud_id,
            Date fecha_solicitud) {
        GenericResponse response = new GenericResponse();

        try {

            Solicitud solicitud = solService.findById(solicitud_id);

            if (solicitud != null && solicitud.getEsMediable() == 1) {

                String jsonResult = repositorio.validar_fecha_sesion(fecha_solicitud);
                // Convertir el JSON resultante en un objeto
                JsonNode jsonNode = objectMapper.readTree(jsonResult);

                int estatus = jsonNode.path("estatus").asInt();
                String fecha = jsonNode.path("fecha").asText();

                if (estatus == 1) {
                    if (asistencia.getEstatus() == 1) {
                        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
                        String fs = fecha;
                        Date fechaSesion = formatter.parse(fs);

                        save(asistencia);
                        solicitud.setFechaSesion(fechaSesion);
                        solService.save(solicitud);

                        response.setSuccess(true);
                        response.setMessage("Datos actualizados con éxito.");
                        response.setData(asistencia);
                        return ResponseEntity.ok(response);

                    } else {
                        List<String> errores = new ArrayList<>();
                        errores.add("No puede cambiar los datos esta invitación");
                        response.setSuccess(false);
                        response.setMessage("Error en la actualización de la información.");
                        response.setErrors(errores);
                        return ResponseEntity.ok(response);
                    }

                } else {
                    List<String> errores = new ArrayList<>();
                    switch (estatus) {
                        case 2:
                            errores.add("La Hora seleccionada no es válida.");
                            errores.add(
                                    "Seleccione una hora entre los siguientes rangos: '08:30', '10:00', '12:00', '13:30'.");
                            break;
                        case 3:
                            errores.add("El día elegido no puede ser sábado o domingo.");
                            break;
                        case 4:
                            errores.add("La fecha seleccionada no puede ser un día inhábil.");
                            break;
                        case 5:
                            errores.add("La fecha seleccionada ya tiene todas las sesiones asignadas.");
                            break;
                    }
                    response.setSuccess(false);
                    response.setMessage("Error en la fecha de sesión.");
                    response.setErrors(errores);
                    return ResponseEntity.ok(response);
                }

            }
        } catch (Exception e) {
            System.out.println(e);
        }

        return null;

    }
}
