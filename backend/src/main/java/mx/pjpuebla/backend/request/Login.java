package mx.pjpuebla.backend.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class Login {
    @NotBlank(message = "Dato requerido")
    private String username;
    
    @NotBlank(message = "Dato requerido")
    private String password;
    
    private String email;
}
