package mx.pjpuebla.backend.core.service;

import java.util.Date;
import java.util.List;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import mx.pjpuebla.backend.configuration.PropertiesApiKey;

@Component
public class JwtService {
    @Autowired
    private PropertiesApiKey properties;

    public String generateJWTToken(String userName, String email){
        List<GrantedAuthority> grantedAuthorities = AuthorityUtils.commaSeparatedStringToAuthorityList("ROLE_USER");
        
        return createToken(userName, email, grantedAuthorities);

    }

    private String createToken(String userName, String email, List<GrantedAuthority> grantedAuthorities){

        String token = Jwts.builder().header().type("JWT").and()
        .id(UUID.randomUUID().toString())
        .issuer(properties.getIssuer())
        .subject(userName)
        .claim("authorities", 
            grantedAuthorities.stream()
            .map(GrantedAuthority::getAuthority)
            .collect(Collectors.toList())).claim("email", email)
        .issuedAt(new Date(System.currentTimeMillis()))
        .expiration(new Date(System.currentTimeMillis() + 24 * 60 * 60 * 1000))
        .signWith(properties.secretKey(), Jwts.SIG.HS256).compact();

        return token;
    }

    public String extractUsername(String token){
        return extractClaim(token, Claims::getSubject);
    }

    public Date extractExpiration(String token){
        return extractClaim(token, Claims::getExpiration);
    }

    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver){
        final Claims claims = extractAllClaims(token);

        return claimsResolver.apply(claims);

    }

    private Claims extractAllClaims(String token){
        return Jwts.parser().verifyWith(properties.secretKey()).build().parseSignedClaims(token).getPayload();
    }

    private boolean isTokenExpired(String token){
        return extractExpiration(token).before(new Date());
    }

    public boolean validateToken(String token, UserDetails userDetails) {
        final String username = extractUsername(token);

        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }

}
