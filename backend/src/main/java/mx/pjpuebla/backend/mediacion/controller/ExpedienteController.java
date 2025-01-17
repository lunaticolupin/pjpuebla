package mx.pjpuebla.backend.mediacion.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.constraints.Null;
import mx.pjpuebla.backend.core.service.FormatoService;
import mx.pjpuebla.backend.mediacion.entitiy.Expediente;
import mx.pjpuebla.backend.mediacion.entitiy.Mediador;
import mx.pjpuebla.backend.mediacion.entitiy.Solicitud;
import mx.pjpuebla.backend.mediacion.service.ExpedienteService;
import mx.pjpuebla.backend.mediacion.service.SolicitudService;
import mx.pjpuebla.backend.mediacion.service.MediadorService;
import mx.pjpuebla.backend.response.GenericResponse;
import lombok.RequiredArgsConstructor;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.hibernate.exception.DataException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.Errors;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import mx.pjpuebla.backend.mediacion.service.MediadorService;

import java.time.LocalDateTime;

import java.util.Date;


@RestController
@RequestMapping("mediacion/expediente")
@RequiredArgsConstructor
public class ExpedienteController {
    
    private final ExpedienteService expedientes;

    private GenericResponse response;

    @Autowired
    private  SolicitudService solicitudService;

    @Autowired
    private  MediadorService mediadorService;

    // @Autowired
    // private Expediente expedienteService;

    @PostMapping("/create")
    public ResponseEntity<GenericResponse> agregar(@RequestParam("mediador_id") Integer mediador_id, @RequestParam("solicitud_id") Integer solicitud_id, @RequestParam("solicitud_mediable") Boolean mediable ) {
        //TODO: process POST request
        response = new GenericResponse();

        try {
            
            Solicitud sol = solicitudService.findById(solicitud_id);
            Mediador med  = mediadorService.findById(mediador_id);

            Expediente exp = expedientes.findBySolicitud(sol.getId());

            if(exp != null)
            {
                exp.setMediador(med);        
                expedientes.save(exp);  
                
                response.setSuccess(true);
                response.setMessage("OK");
                response.setData(exp);
                return ResponseEntity.ok(response);
            } else {
                Expediente expediente = new Expediente();

                //Funcion para obtener el consecutivo de folio

                Integer folioConsecutivo = expedientes.getFolio();
                Integer fol = folioConsecutivo+1;

                

                expediente.setFolio(fol);
                expediente.setFecha_registro(new Date());
                expediente.setMediador(med);
                expediente.setSolicitud(sol);
                expediente.setEs_mediable(mediable);
                expediente.setHay_acuerdo(true);
                expediente.setEstatus(1);

                

                Expediente expedienteNew = expedientes.save(expediente);

                response.setSuccess(true);
                response.setMessage("OK");
                response.setData(expedienteNew);
                return ResponseEntity.ok(response);
            }


        } catch (Exception e) {
            response.setMessage("No se pudo registrar el expediente");
            response.setErrors(e.getMessage());

            e.printStackTrace();
            return ResponseEntity.internalServerError().body(response);
        }

        // return entity;
    }
    

}
