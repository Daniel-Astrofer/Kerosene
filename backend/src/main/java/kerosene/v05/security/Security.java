package kerosene.v05.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class Security {

    // Bean para o codificador de senhas que já discutimos
    @Bean
    public PasswordEncoder passwordEncoder( ) {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http ) throws Exception {
        http
                // 1. Desabilita o CSRF, pois não usamos sessões, mas sim tokens.
                .csrf(csrf -> csrf.disable( ))

                // 2. Configura a gestão de sessão para ser STATELESS (sem estado).
                // A API não vai guardar informações de login na sessão.
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // 3. Configura as regras de autorização para as requisições HTTP.
                .authorizeHttpRequests(auth -> auth
                        // Libera o acesso a qualquer URL que comece com "/api/auth/"
                        // Isso inclui seu login, registro, etc.
                        .requestMatchers("/user/**").permitAll() // <-- ESTA LINHA É CRÍTICA!

                        // Para qualquer outra requisição, o usuário precisa estar autenticado.
                        .anyRequest().authenticated()
                );

        // Constrói a cadeia de filtros de segurança
        return http.build( );
    }
}

