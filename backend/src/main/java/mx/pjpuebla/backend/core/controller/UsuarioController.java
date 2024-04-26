package mx.pjpuebla.backend.core.controller;

import java.util.Arrays;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.web.header.Header;
import org.springframework.stereotype.Controller;
import org.springframework.validation.Errors;
import org.springframework.web.bind.annotation.RequestMapping;

import lombok.RequiredArgsConstructor;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;

import mx.pjpuebla.backend.configuration.PropertiesApiKey;
import mx.pjpuebla.backend.core.entitiy.Persona;
import mx.pjpuebla.backend.core.entitiy.Usuario;
import mx.pjpuebla.backend.core.service.PersonaService;
import mx.pjpuebla.backend.core.service.UsuarioService;
import mx.pjpuebla.backend.models.UsuarioEstatus;
import mx.pjpuebla.backend.request.Login;
import mx.pjpuebla.backend.response.Credencial;
import mx.pjpuebla.backend.response.GenericResponse;

import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.RequestParam;




@Controller
@RequestMapping("usuarios")
@RequiredArgsConstructor
public class UsuarioController {
    @Autowired
    private PropertiesApiKey properties;

    private GenericResponse response;
    private final UsuarioService usuarios;
    private final PersonaService personas;

    @GetMapping("")
    public ResponseEntity<GenericResponse> getUsuarios() {
        response = new GenericResponse();

        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(usuarios.findAll());
        return ResponseEntity.ok(null);
    }

    @GetMapping("/{id}")
    public ResponseEntity<GenericResponse> getUsuarioId(@PathVariable("id") Integer id) {
        Usuario usuario = usuarios.findById(id);

        response = new GenericResponse();

        if (usuario==null){
            response.setMessage("El usuario no existe");

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{clave}")
    public ResponseEntity<GenericResponse> getUsuarioClave(@PathVariable("clave") String claveUsuario) {
        Usuario usuario = usuarios.findByClave(claveUsuario);

        response = new GenericResponse();

        if (usuario==null){
            response.setMessage("No hay resultados");
            response.setData(usuario);

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        response.setSuccess(true);
        response.setData(usuario);

        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/save")
    public ResponseEntity<GenericResponse> guardarUsuario(@Valid @RequestBody Usuario item, Errors errors){
        response = new GenericResponse();

        if (errors.hasErrors()){
            response.setMessage("La entidad no es válida");
            response.setErrors(errors.getAllErrors());

            return ResponseEntity.badRequest().body(response);
        }

        try{
            Persona p = personas.findById(item.getPersonaId());

            if (p==null){
                response.setMessage("No se puede encontrar la Persona relacionada");
                return ResponseEntity.badRequest().body(response);
            }

            item.generarPasswd();
            item.setPersona(p);

            Usuario usuario = usuarios.save(item);

            response.setSuccess(true);
            response.setMessage("OK");
            response.setData(usuario);

            return ResponseEntity.ok(response);
        }catch(Exception e){
            response.setMessage("No se pudo guardar la entidad");
            response.setErrors(Arrays.asList(e.getMessage()));

            return ResponseEntity.internalServerError().body(response);
        }
    }

    @PostMapping("/delete/{id}")
    public ResponseEntity<GenericResponse> eliminarUsuario(@PathVariable("id") Integer id) {
        response = new GenericResponse();
        try{
            if (usuarios.existsById(id)){
                if(usuarios.deleteById(id)){
                    response.setSuccess(true);
                    response.setMessage("OK");
                    
                    return ResponseEntity.ok(response);
                }

                response.setMessage("No se pudo eliminar la entidad");

                return ResponseEntity.internalServerError().body(response);
            }

            response.setMessage("La entidad no existe");

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }catch(Exception e){
            response.setMessage("Error al eliminar la entidad");
            response.setErrors(Arrays.asList(e.getMessage()));

            return ResponseEntity.internalServerError().body(response);
        }
        
        
    }
    
    @PostMapping("/login")
    public ResponseEntity<GenericResponse> login(@RequestBody Login login) {
        Usuario usuario = usuarios.findByClave(login.getUsuario());
        Credencial credencial;

        response = new GenericResponse();

        if (usuario == null){
            response.setMessage("El usuario no existe");

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        if (!usuario.passwordValido(login.getPasswd())){
            response.setMessage("La contraseña es incorrecta");

            return ResponseEntity.badRequest().body(response);
        }

        if (!usuario.esActivo()){
            String mensaje = String.format("Usuario %s", usuario.getEstatus());

            response.setMessage(mensaje);

            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
        }

        credencial = new Credencial(usuario.getClave(), usuario.getCorreoInstitucional());
        credencial.generateJWTToken(properties);

        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(credencial);
        
        usuarios.registrarLogin(usuario);

        return ResponseEntity.ok(response);
    }
    
    @GetMapping("test")
    public ResponseEntity<GenericResponse> test (@RequestHeader("Authorization") Header header) {
        return ResponseEntity.ok(response);
    }
    

}
