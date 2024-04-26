package mx.pjpuebla.backend.response;

import java.util.Date;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

import javax.crypto.SecretKey;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.AuthorityUtils;

import io.jsonwebtoken.Jwts;
import lombok.Data;
import mx.pjpuebla.backend.configuration.PropertiesApiKey;

@Data
public class Credencial {
    private String id;
    private String usuario;
    private String token;
    private String email;
    private Date fecha=new Date();

    public Credencial(String usuario, String email){
        this.id = UUID.randomUUID().toString();
        this.usuario = usuario;
        this.email = email;
    }

    public void generateJWTToken(PropertiesApiKey properties){
        List<GrantedAuthority> grantedAuthorities = AuthorityUtils.commaSeparatedStringToAuthorityList("ROLE_USER");

        String token = Jwts.builder().header().type("JWT").and()
        .id(this.id)
        .issuer(properties.getIssuer())
        .subject(this.usuario)
        .claim("authorities", 
            grantedAuthorities.stream()
            .map(GrantedAuthority::getAuthority)
            .collect(Collectors.toList())).claim("email", this.email)
        .issuedAt(new Date(System.currentTimeMillis()))
        .expiration(new Date(System.currentTimeMillis() + 24 * 60 * 60 * 1000))
        .signWith(properties.secretKey(), Jwts.SIG.HS256).compact();

        this.token = token;

    }
}
