package mx.pjpuebla.backend.reporteador.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import mx.pjpuebla.backend.reporteador.config.JasperReportConfig;
import mx.pjpuebla.backend.reporteador.models.Reportes;
import mx.pjpuebla.backend.reporteador.models.ReportesExporter;
import mx.pjpuebla.backend.response.GenericResponse;

import java.io.InputStream;
import java.util.Arrays;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;

import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@RestController
@RequestMapping("reportes")
public class ReportesController {

    @Autowired
    private JasperReportConfig config;

    @PostMapping(value="/{reporte}",
    produces = {"application/pdf"})
    public ResponseEntity<Object> descargarReporte(@PathVariable("reporte") String reporte, @RequestBody Map<String,Object> parametros) {
        InputStream reporteInputStream = null;
        String nombrePdf = reporte.concat(".pdf");

        try{
            Reportes reportes = config.reportesFiller();
            ReportesExporter exportaReporte = config.reportesExporter();

            reportes.setNombreReporte(reporte);
            reportes.setJasperBase(config.reportesBase());
            reportes.setJasperImages(config.reportesImages());

            reportes.loadReport();

            if (reportes.getReporteJasper()==null){
                throw new java.io.IOException(String.format("El reporte: %s,  no existe", reporte));
            }

            reportes.setParametros(parametros);

            reportes.fillReport();

            exportaReporte.setJasperPrint(reportes.getJasperPrint());
            
            reporteInputStream = exportaReporte.getReporte();

            if (reporteInputStream.available()==0){
                throw new java.io.IOException("No hay datos disponibles");
            }

            return ResponseEntity.ok()
                .contentLength(reporteInputStream.available())
                .contentType(MediaType.APPLICATION_PDF)
                .header("content-disposition", "filename=".concat(nombrePdf))
                .body(new InputStreamResource(reporteInputStream));
        }catch(Exception e){
            return ResponseEntity.internalServerError()
                .contentType(MediaType.APPLICATION_JSON)
                .body(
                    new GenericResponse(false, "Error al descargar el reporte", Arrays.asList(e.getMessage()),null)
                );
        }
        
    }
    
}
