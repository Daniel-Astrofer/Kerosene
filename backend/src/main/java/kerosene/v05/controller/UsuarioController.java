package kerosene.v05.controller;

import kerosene.v05.contracts.*;
import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

/**
 * Controller for user-related operations such as listing, creating, and authenticating users.
 */
@RestController
@RequestMapping("/user")
public class UsuarioController {

   private final LoginVerifier loginVerifier;
   private final SignupVerifier signupVerifier;
   private final TOTPKeyGenerate TOTPKeyGenerator;
   private final Service service;
   private final RedisService redisService;





    public UsuarioController(LoginVerifier loginVerifier,
                             SignupVerifier signupVerifier,
                             TOTPKeyGenerate totpKeyGenerator,
                             @Qualifier("ServiceFromUser") Service service,
                             RedisService redisService) {
        this.loginVerifier = loginVerifier;
        this.signupVerifier = signupVerifier;
        TOTPKeyGenerator = totpKeyGenerator;
        this.service = service;
        this.redisService = redisService;
    }
    /**
     * Lists all users.
     *
     * @return list of users
     */
    @GetMapping("/list")
    public List<UserDataBase> list() {
        return service.listar();
    }

    /**
     * Finds a user by ID.
     *
     * @param id the user ID
     * @return the user if found, otherwise null
     */
    @GetMapping("/id/{id}")
    public UserDataBase find(@PathVariable long id) {
        return service.buscarPorId(id).orElse(null);
    }

    /**
     * Authenticates a user.
     *
     * @param signupUserDTO the user credentials
     * @return ResponseEntity with authentication result
     */
    @PostMapping("/authenticate")
    public boolean authenticateUser(@RequestBody SignupUserDTO signupUserDTO) {
        return loginVerifier.checkUsername(signupUserDTO.getUsername()) && loginVerifier.passphraseMatcher(signupUserDTO.getUsername(), signupUserDTO.getPassphrase());
    }


    @PostMapping("/signup")
    public ResponseEntity<String> createUserInRedis(@RequestBody SignupUserDTO signupUserDTO){

        if (!signupVerifier.verify(signupUserDTO.getUsername(),signupUserDTO.getPassphrase())){
            return ResponseEntity.badRequest().body("fez cagada no  bagulho");
        }

        String key = TOTPKeyGenerator.keyGenerator();
        String otpUri = String.format("otpauth://totp/%s:%s?secret=%s&issuer=%s", "appName", signupUserDTO.getUsername(), key, "appName");


        signupUserDTO.setTOTPSecret(key);

        redisService.createTempUser(signupUserDTO);

        return ResponseEntity.ok(otpUri);
    }
    @PostMapping("/verify")
    public ResponseEntity<String> totpCodeVerify(@RequestBody SignupUserDTO signupUserDTO)  {

        if (!redisService.totpVerify(signupUserDTO)){
            return ResponseEntity.badRequest().body("Not verified");
        }return ResponseEntity.ok("Correct code");
    }

}
