package mx.pjpuebla.backend.reporteador.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import mx.pjpuebla.backend.reporteador.config.JasperReportConfig;
import mx.pjpuebla.backend.reporteador.models.Reportes;
import mx.pjpuebla.backend.reporteador.models.ReportesExporter;
import mx.pjpuebla.backend.response.GenericResponse;
import net.sf.jasperreports.engine.JRParameter;

import java.io.InputStream;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Locale;
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

    @PostMapping(value="/{modulo}/{reporte}",
    produces = {"application/pdf"})
    public ResponseEntity<?> descargarReporte(@PathVariable("modulo") String modulo, @PathVariable("reporte") String nombreReporte, @RequestBody Map<String,Object> parametros) {
        InputStream reporteStream = null;
        String nombrePdf = nombreReporte.concat(".pdf");
        Reportes reportes = null;
        String reporte = String.format("%s/%s", modulo, nombreReporte);

        try{
            ReportesExporter exportaReporte = config.reportesExporter();
            reportes = config.reportesFiller();

            reportes.setNombreReporte(reporte);
            reportes.setJasperBase(config.reportesBase());
            reportes.setJasperImages(config.reportesImages());

            reportes.loadReport();

            if (reportes.getReporteJasper()==null){
                throw new java.io.IOException(String.format("El reporte: %s,  no existe", reporte));
            }

            //parametros.put(JRParameter.REPORT_LOCALE, new Locale("es","MX"));

            reportes.setParametros(parametros);

            reportes.fillReport();

            exportaReporte.setJasperPrint(reportes.getJasperPrint());
            
            reporteStream = exportaReporte.getReporte();

            if (reporteStream.available()==0){
                throw new java.io.IOException("No hay datos disponibles");
            }

            reportes.cerrarConexion();

            return ResponseEntity.ok()
                .contentLength(reporteStream.available())
                .contentType(MediaType.APPLICATION_PDF)
                .header("content-disposition", "filename=".concat(nombrePdf))
                .body(new InputStreamResource(reporteStream));
        }catch(Exception e){
            if (reportes != null){
                try{
                    reportes.cerrarConexion();
                }catch(SQLException ex){
                    ex.printStackTrace();
                }
            }

            return ResponseEntity.internalServerError()
                .contentType(MediaType.APPLICATION_JSON)
                .body(
                    new GenericResponse(false, "Error al descargar el reporte", Arrays.asList(e.getMessage()),null)
                );
        }
        
    }
    
}
