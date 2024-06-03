package mx.pjpuebla.backend.core.controller;

import java.util.Arrays;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.InternalAuthenticationServiceException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import mx.pjpuebla.backend.core.service.JwtService;
import mx.pjpuebla.backend.core.service.UserInfoService;
import mx.pjpuebla.backend.models.UserInfoDetails;
import mx.pjpuebla.backend.request.Login;
import mx.pjpuebla.backend.response.Credencial;
import mx.pjpuebla.backend.response.GenericResponse;

@RestController
@RequiredArgsConstructor
@RequestMapping("session")
public class SessionController {
    private GenericResponse response;
    private final UserInfoService userInfoService;
    private final JwtService jwtService;

    @Autowired
    private AuthenticationManager authenticationManager;

    @GetMapping("/validate")
    public ResponseEntity<GenericResponse> validaToken (@RequestAttribute("usuario") String usuario) {
        response = new GenericResponse(true, "OK", null, usuario);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<GenericResponse> login(@RequestBody Login login) {
        String token;
        UserInfoDetails user;

        response = new GenericResponse();
        try{
            authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(login.getUsername(), login.getPassword()));

            user = (UserInfoDetails) userInfoService.loadUserByUsername(login.getUsername());

            token = jwtService.generateJWTToken(user.getUsername(), user.getEmail());

            userInfoService.saveLogin(user.getUsername());

            response.setSuccess(true);
            response.setMessage("Sesión iniciada");
            response.setData(new Credencial(user.getUsername(), user.getEmail(), token));

            return ResponseEntity.ok(response);
        }catch(InternalAuthenticationServiceException | DisabledException | LockedException | BadCredentialsException e){
            //e.printStackTrace();
            String error = e.getMessage();

            response.setMessage("Error al iniciar sesión");

            if (e.getClass()==BadCredentialsException.class){
                error = "Nombre de Usuario o Password incorrectos";
            }
            response.setErrors(Arrays.asList(error));

            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
        }
        
    }

}
