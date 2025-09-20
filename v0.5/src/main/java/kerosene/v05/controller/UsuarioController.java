package kerosene.v05.controller;

import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;
import kerosene.v05.model.Usuario;
import kerosene.v05.service.cache.UserRedisService;
import kerosene.v05.service.UsuarioService;
import kerosene.v05.service.validation.SignupValidator;
import kerosene.v05.service.validation.TOTPValidator;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controller for user-related operations such as listing, creating, and authenticating users.
 */
@RestController
@RequestMapping("/user")
public class UsuarioController {

    private final UsuarioService service;
    private final UserRedisService redisService;
    private final SignupValidator verification;
    private final TOTPValidator totp;

    /**
     * Constructor for dependency injection.
     *
     * @param service the user service
     */
    public UsuarioController(UsuarioService service,
                             UserRedisService redisService, SignupValidator verification, TOTPValidator totp) {
        this.service = service;
        this.redisService = redisService;

        this.verification = verification;
        this.totp = totp;
    }

    /**
     * Lists all users.
     *
     * @return list of users
     */
    @GetMapping("/list")
    public List<Usuario> list() {
        return service.listar();
    }

    /**
     * Finds a user by ID.
     *
     * @param id the user ID
     * @return the user if found, otherwise null
     */
    @GetMapping("/{id}")
    public Usuario find(@PathVariable long id) {
        return service.buscarPorId(id).orElse(null);
    }

    /**
     * Authenticates a user.
     *
     * @param signupUserDTO the user credentials
     * @return ResponseEntity with authentication result
     */
    @PostMapping("/authenticate")
    public ResponseEntity<String> authenticateUser(@RequestBody SignupUserDTO signupUserDTO) {
        UserDataBase user = service.fromDTO(signupUserDTO);
        return service.auth(signupUserDTO);
    }


    @PostMapping("/signup")
    public ResponseEntity<String> createUserInRedis(@RequestBody SignupUserDTO signupUserDTO){
        String key = totp.keyGenerator();
        String otpUri = String.format("otpauth://totp/%s:%s?secret=%s&issuer=%s", "appName", signupUserDTO.getUsername(), key, "appName");
        verification.verify(service.fromDTO(signupUserDTO));

        signupUserDTO.setTotp_secret(key);

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
