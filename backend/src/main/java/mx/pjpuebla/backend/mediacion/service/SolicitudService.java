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
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.repository.SolicitudRepository;
import mx.pjpuebla.backend.models.SolicitudMediacionEstatus;

@Service
@AllArgsConstructor
public class SolicitudService {
    private final SolicitudRepository repositorio;
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

    public Integer validar_fecha_sesion(Date p_fecha_solicitud) {

     

        try {

            String jsonResult = repositorio.validar_fecha_sesion(p_fecha_solicitud);
            // Convertir el JSON resultante en un objeto
            JsonNode jsonNode = objectMapper.readTree(jsonResult);

            int estatus = jsonNode.path("estatus").asInt();
            String fecha = jsonNode.path("fecha").asText();

            return estatus;

        } catch (JsonProcessingException e) {
            e.printStackTrace();
            return null;
        }

    }

    public boolean registrarDocumento(Integer solicitudId, String claveFormato, String usuario, String personaFirma) {
        return this.repositorio.registrarDocumento(solicitudId, claveFormato, usuario, personaFirma);
    }
}
