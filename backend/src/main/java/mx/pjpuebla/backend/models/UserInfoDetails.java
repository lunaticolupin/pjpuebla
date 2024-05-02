package mx.pjpuebla.backend.models;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import mx.pjpuebla.backend.core.entitiy.Usuario;

public class UserInfoDetails implements UserDetails {
    private String name;
    private String password;
    private UsuarioEstatus status;
    private List<GrantedAuthority> authorities;

    public UserInfoDetails(Usuario usuario){
        name = usuario.getClave();
        password = usuario.getPasswd();
        status = usuario.getEstatus();

        authorities = Arrays.stream(usuario.getRoles().split(","))
        .map(SimpleGrantedAuthority::new)
        .collect(Collectors.toList());
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities(){
        return authorities;
    }

    @Override
    public String getPassword(){
        return password;
    }

    @Override
    public String getUsername(){
        return name;
    }

    @Override
    public boolean isAccountNonExpired(){
        return true;
    }

    @Override
    public boolean isAccountNonLocked(){
        return this.status != UsuarioEstatus.BLOQUEADO;
    }

    @Override
    public boolean isCredentialsNonExpired(){
        return true;
    }

    @Override
    public boolean isEnabled(){
        return this.status == UsuarioEstatus.ACTIVO;
    }

}
