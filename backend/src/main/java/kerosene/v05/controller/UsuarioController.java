package kerosene.v05.controller;

import kerosene.v05.contracts.*;
import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;
import kerosene.v05.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

/**
 * Controller for user-related operations such as listing, creating, and authenticating users.
 */
@RestController
@RequestMapping("/auth")
public class UsuarioController {

   private final LoginVerifier loginVerifier;
   private final SignupVerifier signupVerifier;
   private final TOTPKeyGenerate TOTPKeyGenerator;
   private final Service service;
   private final RedisService redisService;
   private final AuthenticationManager authentication;





    public UsuarioController(LoginVerifier loginVerifier,
                             SignupVerifier signupVerifier,
                             TOTPKeyGenerate totpKeyGenerator,
                             @Qualifier("ServiceFromUser") Service service,
                             RedisService redisService,
                             AuthenticationManager authentication
    ) {
        this.loginVerifier = loginVerifier;
        this.authentication = authentication;
        this.signupVerifier = signupVerifier;
        TOTPKeyGenerator = totpKeyGenerator;
        this.service = service;
        this.redisService = redisService;
    }


    @PostMapping("/login")
    public ResponseEntity<String> authenticateUser(@RequestBody SignupUserDTO signupUserDTO) {
        if(loginVerifier.loginUser(signupUserDTO)){
            return ResponseEntity.status(HttpStatus.ACCEPTED).build();
        }return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }


    @PostMapping("/signup")
    public ResponseEntity<Object> createUserInRedis(@RequestBody SignupUserDTO signupUserDTO){

        if (!signupVerifier.verify(signupUserDTO.getUsername(),signupUserDTO.getPassphrase())){
            return ResponseEntity.status(HttpStatus.CONFLICT).build();
        }

        String key = TOTPKeyGenerator.keyGenerator();
        String otpUri = String.format("otpauth://totp/%s:%s?secret=%s&issuer=%s", "Kerosene", signupUserDTO.getUsername(), key, "Kerosene");

        signupUserDTO.setTotpSecret(key);

        redisService.createTempUser(signupUserDTO);

        return ResponseEntity.ok(key);

    }
    @PostMapping("/code")
    public ResponseEntity<String> totpCodeVerify(@RequestBody SignupUserDTO signupUserDTO)  {

        if (!redisService.totpVerify(signupUserDTO)){
            return ResponseEntity.status(HttpStatus.NOT_ACCEPTABLE).build();
        }
        Authentication auth = authentication.authenticate(
                new UsernamePasswordAuthenticationToken(
                        signupUserDTO.getUsername(),
                        signupUserDTO.getPassphrase()
                )
        );return ResponseEntity.status(HttpStatus.CREATED).build();
    }

}
