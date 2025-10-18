package kerosene.v05;

import kerosene.v05.controller.UsuarioController;
import kerosene.v05.repository.UsuarioRepository;
import kerosene.v05.service.UsuarioService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}
    
}
