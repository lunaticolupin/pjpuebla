package mx.pjpuebla.backend.response;

import java.util.Date;

import lombok.Data;

@Data
public class Credencial {
    private String usuario;
    private String token;
    private String email;
    private Date fecha=new Date();

    public Credencial(String usuario, String email, String token){
        this.usuario = usuario;
        this.email = email;
        this.token = token;
    }
}
