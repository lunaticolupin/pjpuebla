package mx.pjpuebla.backend.mediacion.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.mediacion.entitiy.Asistencia;
import mx.pjpuebla.backend.mediacion.entitiy.SesionMediacion;
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.service.AsistenciaService;
import mx.pjpuebla.backend.response.GenericResponse;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.Errors;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;



@RestController
@RequestMapping("mediacion/asistencias")
@RequiredArgsConstructor
public class AsistenciaController {
    private GenericResponse response;
    private final AsistenciaService asistenciaService;

    @PostMapping("/add")
    public ResponseEntity<GenericResponse> agregar(@Valid @RequestBody Asistencia entidad,  Errors errors){
        Integer esAgendable;
        response = new GenericResponse();
        List<String> errores;
        response.setSuccess(false);

        if (errors.hasErrors()){
            response.setMessage("La entidad tiene errores");
            response.setErrors(errors.getAllErrors());

            return ResponseEntity.badRequest().body(response);
        }
        
        if (entidad.getId()!=null){
            response.setMessage("La entidad ya existe");

            return ResponseEntity.badRequest().body(response);
        }

        esAgendable = asistenciaService.esAgendable(entidad.getSolicitud().getId());

        if(esAgendable == 1){
            Asistencia asistencia = asistenciaService.obtenerFecha(entidad.getSolicitud().getId());
            if(asistencia  != null){
                response.setData(asistencia);
                response.setSuccess(true);
                response.setMessage("OK");
            }else{
                response.setMessage("Ocurrio un error al generar su fecha de invitación");
                errores = new ArrayList<>();
                errores.add("Ha ocurrido un error al generar la fecha de invitación");
                response.setErrors(errores);
            }
        }else if(esAgendable == 2){
           
            errores = new ArrayList<>();
            errores.add("No es posible agendar mas invitaciones ya que las personas han aceptado la mediación.");
            response.setErrors(errores);
            response.setMessage("Error al generar invitación.");

        }else if(esAgendable == 3){
            errores = new ArrayList<>();
            errores.add("No es posible agendar mas invitaciones para esta solicitud.");
            response.setErrors(errores);
            response.setMessage("Error al generar invitación.");
       
        }else if(esAgendable == 4){
            errores = new ArrayList<>();
            errores.add("No es posible generar una nueva invitación ya que aun sigue activa una.");
            response.setErrors(errores);
            response.setMessage("Error al generar invitación.");
        }

        return ResponseEntity.ok(response);


    }
    
    @PostMapping("/save/{id}")
    public ResponseEntity<GenericResponse>  guardar(@Valid @RequestBody Asistencia entidad, Errors errors ) {
        if (errors.hasErrors()) {
            GenericResponse response = new GenericResponse();
            response.setMessage("La entidad tiene errores");
            response.setErrors(errors.getAllErrors());
            return ResponseEntity.badRequest().body(response);
        }

        return asistenciaService.actualizarAsistencia(entidad, entidad.getSolicitud().getId(), entidad.getFechaAsistencia());
    }
    

    @GetMapping("/findBySolicitudId/{solicitud_id}")
    public ResponseEntity<GenericResponse> getAsistenciasBySolicitud(@PathVariable("solicitud_id") Integer solicitud_id){
        response = new GenericResponse(true, "OK", null, null);

        List<Asistencia> asistencia = asistenciaService.findAllBySolicitudIdOrderByFechaAsistenciaAsc(solicitud_id);
        response.setData(asistencia);

        return ResponseEntity.ok(response);
    }
    
    @GetMapping("template")
    public ResponseEntity<GenericResponse> getJsonTemplate() {
        Asistencia template = new Asistencia();
        Solicitud solicitud = new Solicitud();
        SesionMediacion sesionMediacion = new SesionMediacion();


        template.setSolicitud(solicitud);
        template.setSesionMediacion(sesionMediacion);

        response = new GenericResponse(true, "OK", null, template);

        return ResponseEntity.ok(response);
        
    }
    
    
}
