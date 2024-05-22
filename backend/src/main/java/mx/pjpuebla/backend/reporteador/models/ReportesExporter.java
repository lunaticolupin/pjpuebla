package mx.pjpuebla.backend.reporteador.models;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.springframework.stereotype.Component;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.export.JRPdfExporter;
import net.sf.jasperreports.export.SimpleExporterInput;
import net.sf.jasperreports.export.SimpleOutputStreamExporterOutput;
import net.sf.jasperreports.export.SimplePdfExporterConfiguration;
import net.sf.jasperreports.export.SimplePdfReportConfiguration;

@Component
public class ReportesExporter {
    private JasperPrint jasperPrint;

    public ReportesExporter(){

    }

    public ReportesExporter(JasperPrint jasperPrint) {
        this.jasperPrint = jasperPrint;
    }

    public void exportarPdf(String nombre, String autor){
        JRPdfExporter exporter = new JRPdfExporter();

        exporter.setExporterInput(new SimpleExporterInput(jasperPrint));
        exporter.setExporterOutput(new SimpleOutputStreamExporterOutput(nombre));

        SimplePdfReportConfiguration reportConfig = new SimplePdfReportConfiguration();
        reportConfig.setSizePageToContent(true);
        reportConfig.setForceLineBreakPolicy(false);

        SimplePdfExporterConfiguration exportConfig = new SimplePdfExporterConfiguration();
        exportConfig.setMetadataAuthor(autor);
        exportConfig.setEncrypted(true);
        exportConfig.setAllowedPermissionsHint("PRINTING");

        exporter.setConfiguration(reportConfig);
        exporter.setConfiguration(exportConfig);

        try {
            exporter.exportReport();
        } catch (JRException ex) {
            Logger.getLogger(ReportesExporter.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    public InputStream getReporte(){
        JRPdfExporter exporter = new JRPdfExporter();
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        exporter.setExporterInput(new SimpleExporterInput(jasperPrint));
        exporter.setExporterOutput(new SimpleOutputStreamExporterOutput(out));

        try{
            exporter.exportReport();

            return new ByteArrayInputStream(out.toByteArray());
        }catch (JRException ex) {

            Logger.getLogger(ReportesExporter.class.getName()).log(Level.SEVERE, null, ex);

            return null;
        }
        
    }



    public JasperPrint getJasperPrint() {
        return jasperPrint;
    }



    public void setJasperPrint(JasperPrint jasperPrint) {
        this.jasperPrint = jasperPrint;
    }


}
