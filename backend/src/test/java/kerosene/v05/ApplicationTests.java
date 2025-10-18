package kerosene.v05;

import kerosene.v05.contracts.Service;

import kerosene.v05.contracts.User;
import kerosene.v05.model.UserDataBase;
import kerosene.v05.repository.UsuarioRepository;
import kerosene.v05.service.UsuarioService;
import kerosene.v05.service.validation.SignupValidator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static reactor.core.publisher.Mono.when;


@ExtendWith(MockitoExtension.class)
class ApplicationTests {

	@Mock
    private UsuarioRepository repository;


    @InjectMocks
    private SignupValidator validator;;



    @Test
    void listar_DeveRetornarListaDeUsuarios() {
        String username = "Marcelo";
        String passphrase = "pattern artist accuse valve appear intact enroll fork industry year toilet behind core document height hen mesh prosper";

        Mockito.when(repository.findByUsername(username)).thenReturn(null);


        boolean resultado = validator.verify(username, passphrase);

        // Regra 3: O username do primeiro usuário DEVE SER "maraiana".
        assertTrue(resultado,"Nao sei");

    }


}
