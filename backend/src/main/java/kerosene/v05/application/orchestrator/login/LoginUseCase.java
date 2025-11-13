package kerosene.v05.application.orchestrator.login;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.application.orchestrator.login.contracts.Login;
import kerosene.v05.application.service.authentication.contracts.LoginVerifier;
import kerosene.v05.dto.contracts.UserDTO;
import kerosene.v05.model.contracts.UserDB;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.context.SecurityContextHolderThreadLocalAccessor;
import org.springframework.stereotype.Component;

@Component
public class LoginUseCase implements Login {

    private final LoginVerifier verifier;

    public LoginUseCase(LoginVerifier verifier) {
        this.verifier = verifier;
    }


    /*
    * check if the jwt is correct and assigned and give back the id from user on jwt
    * if the jwt is invalid the code check username and passphrase and throws RuntimeException if incorrect*/
    @Override
    public String loginUser(UserDTO dto, HttpServletRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String id = auth.getName();

        if (id == null || id.isEmpty() || id.equalsIgnoreCase("anonymousUser")) {
            UserDB user = verifier.matcher(dto,request) ;
            id = String.valueOf(user.getId());
        }
        return id;

    }
}
