package kerosene.v05.controller;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.application.orchestrator.login.contracts.Login;
import kerosene.v05.application.orchestrator.login.contracts.Signup;
import kerosene.v05.dto.UserDTO;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Controller for user-related operations such as listing, creating, and authenticating users.
 */
@RestController
@RequestMapping("/auth")
public class UsuarioController {
   private final Login login;
   private final Signup signup;

    public UsuarioController(Login login,
                             Signup signup
    ) {
        this.login = login;
        this.signup = signup;
    }

    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestBody UserDTO userDTO, HttpServletRequest request) {
        String id = login.loginUser(userDTO,request);

        return ResponseEntity.status(HttpStatus.ACCEPTED).body(id) ;
    }
    @PostMapping("/signup")
    public ResponseEntity<String> signup(@RequestBody UserDTO userDTO, HttpServletRequest request){
        String key = signup.signupUser(userDTO);

        return ResponseEntity.status(HttpStatus.ACCEPTED).body(key);
    }
    @PostMapping("/signup/totp/verify")
    public ResponseEntity<String> totpCodeVerify(@RequestBody UserDTO userDTO, HttpServletRequest request)  {
        String token = signup.createUser(userDTO,request);
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(token);
    }

}
