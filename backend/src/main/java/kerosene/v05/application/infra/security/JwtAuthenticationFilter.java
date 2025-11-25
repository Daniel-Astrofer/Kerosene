package kerosene.v05.application.infra.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import kerosene.v05.application.service.validation.jwt.contracts.JwtServicer;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;



public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtServicer jwtService;



    public JwtAuthenticationFilter(
            @Qualifier("JwtService") JwtServicer jwtService) {
        this.jwtService = jwtService;
    }


    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {

        String header =  request.getHeader("Authorization");

        if (header != null && header.startsWith("Bearer ") ){
            String token = header.substring(7);

            try{

                String device = jwtService.extractDevice(token);
                UsernamePasswordAuthenticationToken auth = new UsernamePasswordAuthenticationToken(jwtService.extractId(token),null,Collections.singletonList(() -> "USER")  );
                SecurityContextHolder.getContext().setAuthentication(auth);



            }catch (Exception e ) {
                SecurityContextHolder.clearContext();





            }
        }

        filterChain.doFilter(request,response);
    }
}
