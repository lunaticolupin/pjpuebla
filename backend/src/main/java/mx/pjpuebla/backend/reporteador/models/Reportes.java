package mx.pjpuebla.backend.reporteador.models;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ResourceLoader;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;

import net.sf.jasperreports.engine.JRException;
import net.sf.jasperreports.engine.JasperCompileManager;
import net.sf.jasperreports.engine.JasperFillManager;
import net.sf.jasperreports.engine.JasperPrint;
import net.sf.jasperreports.engine.JasperReport;
import net.sf.jasperreports.engine.util.JRLoader;
import net.sf.jasperreports.engine.util.JRSaver;

@Component
public class Reportes {
    private String nombreReporte;
    private JasperReport reporteJasper;
    private JasperPrint jasperPrint;
    private String jasperBase;
    private String jasperImages;
    private Connection conn;

    @Autowired
    private DataSource dataSource;

    @Autowired
    private ResourceLoader resourceLoader;

    private Map<String, Object> parametros;

    public Reportes(){
        parametros = new HashMap<>();
    }

    public void preparaReporte(){
        compileReport();
        fillReport();
    }

    public void compileReport(){
        String tmp = jasperBase.concat(nombreReporte.concat(".jrxml"));

        try{
            InputStream reporteStream = resourceLoader.getResource(tmp).getInputStream();
            reporteJasper = JasperCompileManager.compileReport(reporteStream);
            JRSaver.saveObject(reporteJasper, tmp.replace(".jrxml", ".jasper"));
        }catch(IOException | JRException ex){
            Logger.getLogger(Reportes.class.getName()).log(Level.SEVERE, null, ex);
        } 
    }

    public void loadReport(){
        String tmp = jasperBase.concat(nombreReporte.concat(".jasper"));

        try{
            InputStream reporteStream = resourceLoader.getResource(tmp).getInputStream();
            reporteJasper = (JasperReport) JRLoader.loadObject(reporteStream);
        }catch(IOException | JRException ex){
            Logger.getLogger(Reportes.class.getName()).log(Level.SEVERE, null, ex);
            compileReport();
        }
    }

    public void fillReport(){
        try{
            conn = dataSource.getConnection();
            jasperPrint = JasperFillManager.fillReport(reporteJasper, parametros, conn);
            //dataSource.getConnection().close();
        }catch(JRException | SQLException ex){
            Logger.getLogger(Reportes.class.getName()).log(Level.SEVERE, null, ex);
        }
    }

    public String getNombreReporte() {
        return nombreReporte;
    }

    public void setNombreReporte(String nombreReporte) {
        this.nombreReporte = nombreReporte;
    }

    public JasperReport getReporteJasper() {
        return reporteJasper;
    }

    public void setReporteJasper(JasperReport reporteJasper) {
        this.reporteJasper = reporteJasper;
    }

    public JasperPrint getJasperPrint() {
        return jasperPrint;
    }

    public void setJasperPrint(JasperPrint jasperPrint) {
        this.jasperPrint = jasperPrint;
    }

    public DataSource getDataSource() {
        return dataSource;
    }

    public void setDataSource(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public Map<String, Object> getParametros() {
        return parametros;
    }

    public void setParametros(Map<String, Object> parametros) {
        this.parametros = parametros;

        this.parametros.put("p_image_path", jasperImages);
    }

    public void setJasperBase(String jasperBase){
        this.jasperBase = jasperBase;
    }

    public String getJasperBase(){
        return this.jasperBase;
    }

    public String getJasperImages() {
        return jasperImages;
    }

    public void setJasperImages(String jasperImages) {
        this.jasperImages = jasperImages;
    }

    public void cerrarConexion() throws SQLException{
        if (conn != null && !conn.isClosed()){
            conn.close();
        }
    }
}
