package mx.pjpuebla.backend.reporteador.config;

import javax.sql.DataSource;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import mx.pjpuebla.backend.reporteador.models.Reportes;
import mx.pjpuebla.backend.reporteador.models.ReportesExporter;

@Configuration
public class JasperReportConfig {

    @Autowired
    private Environment env;

    @Bean
    public DataSource dataSource(){
        DataSourceBuilder dataSourceBuilder = DataSourceBuilder.create();
        dataSourceBuilder.driverClassName("org.postgresql.Driver");
        dataSourceBuilder.url(env.getProperty("spring.datasource.url"));
        dataSourceBuilder.username(env.getProperty("spring.datasource.username")); 
        dataSourceBuilder.password(env.getProperty("spring.datasource.password")); 

        return dataSourceBuilder.build();
    }

    @Bean
    public Reportes reportesFiller(){
        return new Reportes();
    }

    @Bean

    public ReportesExporter reportesExporter(){
        return new ReportesExporter();
    }

    public String reportesBase(){
        return env.getProperty("api.reportes.jasper");
    }

    public String reportesImages(){
        return env.getProperty("api.reportes.images");
    }
}
 