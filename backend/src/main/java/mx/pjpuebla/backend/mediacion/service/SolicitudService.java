package mx.pjpuebla.backend.mediacion.service;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.AllArgsConstructor;
import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.core.service.PersonaService;
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.entitiy.SolicitudCanalizacion;
import mx.pjpuebla.backend.mediacion.repository.SolicitudRepository;
import mx.pjpuebla.backend.models.SolicitudMediacionEstatus;
import mx.pjpuebla.backend.response.GenericResponse;

@Service
@AllArgsConstructor
public class SolicitudService {
    private final SolicitudRepository repositorio;
    private final PersonaService personaService;
    private final SolicitudCanalizacionService solicitudCanalizacionService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public List<Solicitud> findAll() {
        return this.repositorio.findAll();
    }

    public Solicitud findById(Integer id) {
        Optional<Solicitud> solicitud = this.repositorio.findById(id);

        if (solicitud.isPresent()) {
            return solicitud.get();
        }

        return null;
    }

    public Solicitud findByFolio(String folio) {
        return this.repositorio.findByFolio(folio);
    }

    public Solicitud save(Solicitud solicitud) {
        return this.repositorio.save(solicitud);
    }

    public boolean delete(Integer id) {
        try {
            this.repositorio.deleteById(id);

            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public String generarFolio(String claveArea) {
        return this.repositorio.generarFolio(claveArea);
    }

    public boolean esEliminable(Integer id) {
        Optional<Solicitud> solicitud = this.repositorio.findById(id);

        if (solicitud.isEmpty()) {
            return false;
        }

        return solicitud.get().getEstatus() != SolicitudMediacionEstatus.RECEPCION;
    }

    public Date generarFechaSesion(Integer solicitudId) {
        try {

            String jsonResult = this.repositorio.generarFechaSesion();
            JsonNode jsonNode = objectMapper.readTree(jsonResult);
            // Define el formato de la cadena
            SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
            String fs = jsonNode.path("fecha").asText();
            Date fechaSesion = formatter.parse(fs);

            Optional<Solicitud> entity = this.repositorio.findById(solicitudId);

            if (fechaSesion != null && entity.isPresent()) {
                Solicitud solicitud = entity.get();

                if (solicitud.getFechaSesion() != null) {
                    return solicitud.getFechaSesion();
                }

                solicitud.setFechaSesion(fechaSesion);
                solicitud.setFechaActualizacion(new Date());
                this.repositorio.save(solicitud);
            }

            return fechaSesion;
        } catch (JsonProcessingException | ParseException e) {
            // Manejar excepciones de procesamiento JSON
            e.printStackTrace();
            return null;
        }
    }



    public boolean registrarDocumento(Integer solicitudId, String claveFormato, String usuario, String personaFirma) {
        return this.repositorio.registrarDocumento(solicitudId, claveFormato, usuario, personaFirma);
    }

    public ResponseEntity<GenericResponse> procesarSolicitud(Solicitud entidad) {
        GenericResponse response = new GenericResponse();

        // Tratamiento de la persona y el invitado
        String curpOrRfcInvitado = entidad.getInvitadoPersona().getPersonaMoral()
                ? entidad.getInvitadoPersona().getRfc()
                : entidad.getInvitadoPersona().getCurp();
        String curpOrRfcPersona = entidad.getUsuarioPersona().getPersonaMoral() ? entidad.getUsuarioPersona().getRfc()
                : entidad.getUsuarioPersona().getCurp();

        Persona usuarioInvitado = personaService.findByCurpOrRfc(curpOrRfcInvitado);
        Persona usuarioPersona = personaService.findByCurpOrRfc(curpOrRfcPersona);

        if (usuarioInvitado == null) {
            usuarioInvitado = personaService.save(entidad.getInvitadoPersona());
        }
        if (usuarioPersona == null) {
            usuarioPersona = personaService.save(entidad.getUsuarioPersona());
        }

        entidad.setInvitadoPersona(usuarioInvitado);
        entidad.setUsuarioPersona(usuarioPersona);
        
        // Manejo de la canalización
        if (entidad.getEsMediable() == 2) {
            SolicitudCanalizacion sol = entidad.getCanalizacion();
            if(sol.getDescripcion().isEmpty()){
                List<String> errores = new ArrayList<>();
                errores.add("Es necesario escribir algun motivo por el cual no se considera mediable");
                response.setSuccess(false);
                response.setMessage("Error al guardar la información");
                response.setErrors(errores);
                return ResponseEntity.ok(response);
            }
            

            if (entidad.getCanalizacion().getId() != null) {
                SolicitudCanalizacion solicitudEntity = entidad.getCanalizacion();

                solicitudEntity.setDescripcion(solicitudEntity.getDescripcion());
                solicitudEntity.setFecha_actualizacion(new Date());
                solicitudEntity.setEstatus(1);
                
                //Evaluamos si el ha sido canalizada a una institución si lo ha sido asignamos la institucion canalizada si no lo ha sido eliminamos cualquier canalización que se tenga
                if(solicitudEntity.getEstatus() == 1){ solicitudEntity.setInstitucion(solicitudEntity.getInstitucion()); }
                else { solicitudEntity.setInstitucion(null); }
               
                entidad.setCanalizacion(solicitudCanalizacionService.save(entidad.getCanalizacion()));

            } else {
                SolicitudCanalizacion nuevaCanalizacion = new SolicitudCanalizacion();
                nuevaCanalizacion.setFecha_creacion(null);
                nuevaCanalizacion.setSolicitud(entidad);
                nuevaCanalizacion.setDescripcion(entidad.getCanalizacion().getDescripcion());
                nuevaCanalizacion.setFecha_actualizacion(new Date());
                nuevaCanalizacion.setEstatus(1);
                nuevaCanalizacion.setInstitucion(entidad.getCanalizacion().getInstitucion());
                nuevaCanalizacion.setFecha_creacion(new Date());
                entidad.setCanalizacion(solicitudCanalizacionService.save(nuevaCanalizacion));
            }

        }

        if(entidad.getEsMediable() == 0){
            if (entidad.getCanalizacion().getId() != null) {
                SolicitudCanalizacion solicitudEntity = entidad.getCanalizacion();

                solicitudEntity.setDescripcion("");
                solicitudEntity.setFecha_actualizacion(new Date());
                solicitudEntity.setEstatus(0);
                solicitudEntity.setInstitucion(null);
                entidad.setCanalizacion(solicitudCanalizacionService.save(entidad.getCanalizacion()));
            }
        }

        // Actualización de la solicitud
        entidad.setFechaActualizacion(new Date());
        entidad.setUsuarioActualizo("TEST");
        entidad.setUsuarioCreo("TEST");

        response.setSuccess(true);
        response.setMessage("OK");

        Solicitud solicitudActualizada = save(entidad);
        response.setData(solicitudActualizada);

        return ResponseEntity.ok(response);
    }

}
