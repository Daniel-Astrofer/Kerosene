package kerosene.v05.controller;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.application.orchestrator.login.contracts.Login;
import kerosene.v05.application.orchestrator.login.contracts.Signup;
import kerosene.v05.application.orchestrator.signup.SignupUseCase;
import kerosene.v05.application.service.validation.totp.contratcs.TOTPKeyGenerate;
import kerosene.v05.application.service.user.contract.UserServiceContract;
import kerosene.v05.application.service.validation.ip_handler.contracts.IP;
import kerosene.v05.application.service.cache.contracts.RedisService;
import kerosene.v05.application.service.authentication.contracts.SignupVerifier;
import kerosene.v05.application.service.validation.totp.contratcs.TOTPVerifier;
import kerosene.v05.dto.UserDTO;
import kerosene.v05.model.entity.UserDataBase;
import kerosene.v05.model.entity.UserDevice;
import kerosene.v05.application.service.device.UserDeviceService;
import kerosene.v05.application.infra.security.JwtService;
import org.springframework.beans.factory.annotation.Qualifier;
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
