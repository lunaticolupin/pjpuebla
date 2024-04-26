package mx.pjpuebla.backend.security;

import org.springframework.beans.factory.annotation.Autowired;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.pjpuebla.backend.configuration.PropertiesApiKey;

public class JWTAuthorizationFilter {
	private final String PREFIX = "Bearer ";

    @Autowired
    private PropertiesApiKey properties;

    private Claims validateToken(HttpServletRequest request){
        String jwtToken = request.getHeader(properties.getHeader()).replace(PREFIX, "");

        return Jwts.parser().verifyWith(properties.secretKey()).build().parseSignedClaims(jwtToken).getPayload();
    }

    private boolean checkJWTToken(HttpServletRequest request, HttpServletResponse response){
        String authenticationHeader = request.getHeader(properties.getHeader());

        if (authenticationHeader == null || authenticationHeader.isEmpty())
            return false;

        return true;
    }
}
