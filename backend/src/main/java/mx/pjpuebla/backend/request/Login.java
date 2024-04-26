package mx.pjpuebla.backend.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class Login {
    @NotBlank(message = "Dato requerido")
    private String usuario;
    
    @NotBlank(message = "Dato requerido")
    private String passwd;
    
    private String email;
}
