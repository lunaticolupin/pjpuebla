package mx.pjpuebla.backend.core.controller;

import java.util.Arrays;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.validation.Errors;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;

import mx.pjpuebla.backend.core.entitiy.Persona;
/*import mx.pjpuebla.backend.core.entitiy.Rol;
import mx.pjpuebla.backend.core.entitiy.RolUsuario;
import mx.pjpuebla.backend.core.entitiy.RolUsuarioKey;*/
import mx.pjpuebla.backend.core.entitiy.Usuario;
import mx.pjpuebla.backend.core.service.JwtService;
import mx.pjpuebla.backend.core.service.PersonaService;
//import mx.pjpuebla.backend.core.service.RolUsuarioService;
import mx.pjpuebla.backend.core.service.UserInfoService;
import mx.pjpuebla.backend.core.service.UsuarioService;

import mx.pjpuebla.backend.request.Login;
import mx.pjpuebla.backend.response.Credencial;
import mx.pjpuebla.backend.response.GenericResponse;

import jakarta.validation.Valid;

@RestController
@RequestMapping("usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private GenericResponse response;
    private final UsuarioService usuarios;
    private final PersonaService personas;
    private final UserInfoService service;
    private final JwtService jwtService;
    //private final RolUsuarioService rolesUsuarios;

    @Autowired
    private AuthenticationManager authenticationManager;

    @GetMapping("")
    public ResponseEntity<GenericResponse> getUsuarios() {
        response = new GenericResponse();

        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(usuarios.findAll());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<GenericResponse> getUsuarioId(@PathVariable("id") Integer id) {
        Usuario usuario = usuarios.findById(id);

        response = new GenericResponse();

        if (usuario==null){
            response.setMessage("El usuario no existe");

            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }

        response.setSuccess(true);
        response.setMessage("OK");
        response.setData(usuario);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/find/{clave}")
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

    
    @GetMapping("/test")
    public ResponseEntity<GenericResponse> test (@RequestAttribute("usuario") String usuario) {
        response = new GenericResponse(true, "OK", null, usuario);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/login")
    public ResponseEntity<GenericResponse> login(@RequestBody Login login) {
        response = new GenericResponse();
        try{
            authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(login.getUsername(), login.getPassword()));
            String token;

            token = jwtService.generateJWTToken(login.getUsername(), login.getEmail());

            service.saveLogin(login.getUsername());

            response.setSuccess(true);
            response.setMessage("OK");
            response.setData(new Credencial(login.getUsername(), login.getEmail(), token));

            return ResponseEntity.ok(response);
        }catch(DisabledException | LockedException | BadCredentialsException e){
            response.setMessage("Error al iniciar sesión");
            response.setErrors(Arrays.asList(e.getMessage()));

            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(response);
        }
        
    }

    @PostMapping("/add")
    public ResponseEntity<GenericResponse> addUser(@RequestBody Usuario usuario) {

        boolean result;
        response = new GenericResponse();
        
        Persona p = personas.findById(usuario.getPersonaId());

            if (p==null){
                response.setMessage("No se puede encontrar la Persona relacionada");
                return ResponseEntity.badRequest().body(response);
            }

            usuario.setPersona(p);
            result    = service.addUser(usuario);

        

        if (result){
            response.setSuccess(result);
            response.setMessage("OK");
            return ResponseEntity.ok(response); 
        }

        return ResponseEntity.internalServerError().body(response);
    }
    
    /*@PostMapping("{usuario_id}/agregar/{rol_id}")
    public ResponseEntity<GenericResponse> agregarRol(@PathVariable("usuario_id") Integer usuarioId, @PathVariable("rol_id") Integer rolId) {
        
        RolUsuario rolUsuario = new RolUsuario();
        RolUsuarioKey key = new RolUsuarioKey(usuarioId, rolId);

        rolUsuario.setId(key);
        rolUsuario.setUsuarioCreo("TEST");
        
        response = new GenericResponse();

        if (rolesUsuarios.save(rolUsuario)){
            response.setSuccess(true);
            response.setMessage("OK");
            response.setData(rolUsuario);
            return ResponseEntity.ok(response);
        }

        response.setMessage("ERROR");
        
        return ResponseEntity.badRequest().body(response);
    }*/
    
    

}
