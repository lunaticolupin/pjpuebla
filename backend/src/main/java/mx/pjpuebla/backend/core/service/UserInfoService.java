package mx.pjpuebla.backend.core.service;

import java.util.Date;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import mx.pjpuebla.backend.core.entitiy.Usuario;
import mx.pjpuebla.backend.core.repository.UsuarioRepository;
import mx.pjpuebla.backend.models.UserInfoDetails;

@Service
public class UserInfoService implements UserDetailsService {
    @Autowired
    private UsuarioRepository repository;

    @Autowired
    private PasswordEncoder encoder;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Optional<Usuario> userDetail = repository.findByClave(username);

        return userDetail.map(UserInfoDetails::new).orElseThrow(()-> new UsernameNotFoundException("Usuario no existe"));
    }

    public boolean addUser(Usuario usuario){
        usuario.setPasswd(encoder.encode(usuario.getPasswdTxt()));

        repository.save(usuario);

        return true;
    }

    public void saveLogin(String username){
        Usuario usuario = repository.findByClave(username).get();

        usuario.setLastLogin(new Date());
        repository.save(usuario);
    }
}
