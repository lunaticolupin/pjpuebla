package mx.pjpuebla.backend.security;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Arrays;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.fasterxml.jackson.databind.ObjectMapper;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.UnsupportedJwtException;
import io.jsonwebtoken.security.SignatureException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import mx.pjpuebla.backend.core.service.JwtService;
import mx.pjpuebla.backend.core.service.UserInfoService;
import mx.pjpuebla.backend.response.GenericResponse;

@Component
public class JWTAuthorizationFilter extends OncePerRequestFilter {

    @Autowired
    private UserInfoService userDetailsService;

    @Autowired
    private JwtService jwtService;

    @SuppressWarnings("null")
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException{
        String authHeader = request.getHeader("Authorization");
        String token = null;
        String username = null;

        try{
            if(authHeader != null && authHeader.startsWith("Bearer ")){
                token = authHeader.replace("Bearer ", "");
                username = jwtService.extractUsername(token);
            }
    
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null){
                UserDetails userDetails = userDetailsService.loadUserByUsername(username);
    
                if (jwtService.validateToken(token, userDetails)){
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());

                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                    request.setAttribute("usuario", username);
                }
            }
    
            filterChain.doFilter(request, response);
        } catch (ExpiredJwtException | UnsupportedJwtException | MalformedJwtException | SignatureException   e) {
            GenericResponse respuesta = new GenericResponse();

            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.setCharacterEncoding("UTF-8");

            PrintWriter writer = response.getWriter();

            respuesta.setMessage("ACCESO DENEGADO");
            respuesta.setErrors(Arrays.asList(e.getMessage()));

            writer.print(new ObjectMapper().writeValueAsString(respuesta));
            writer.flush();
            writer.close();
			return;
        }
    }

}
