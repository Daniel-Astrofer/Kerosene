package vault;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class VaultApplication {

    public static void main(String[] args) {
        // Remove referências extras para dificultar ataques via propriedades do Spring
        System.setProperty("spring.main.banner-mode", "off");
        SpringApplication.run(VaultApplication.class, args);
    }
}
