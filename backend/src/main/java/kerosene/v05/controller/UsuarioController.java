package kerosene.v05.controller;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.contracts.*;
import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;
import kerosene.v05.model.UserDevice;
import kerosene.v05.repository.UsuarioRepository;
import kerosene.v05.service.UserDeviceService;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.autoconfigure.graphql.GraphQlProperties;
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
   private final UserDeviceService deviceService;
   private final IP ip;





    public UsuarioController(LoginVerifier loginVerifier,
                             SignupVerifier signupVerifier,
                             TOTPKeyGenerate totpKeyGenerator,
                             @Qualifier("ServiceFromUser") Service service,
                             RedisService redisService, UserDeviceService deviceService,
                             @Qualifier("IPValidator") IP ip

    ) {
        this.loginVerifier = loginVerifier;

        this.signupVerifier = signupVerifier;
        TOTPKeyGenerator = totpKeyGenerator;
        this.service = service;
        this.redisService = redisService;
        this.deviceService = deviceService;
        this.ip = ip;
    }

    
    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestBody SignupUserDTO signupUserDTO,HttpServletRequest request) {
        if(loginVerifier.Matcher(signupUserDTO,request)){
            return ResponseEntity.status(HttpStatus.ACCEPTED).build();
        }return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
    }


    @PostMapping("/signup")
    public ResponseEntity<Object> createUserInRedis(@RequestBody SignupUserDTO signupUserDTO, HttpServletRequest request){


        if (!signupVerifier.verify(signupUserDTO.getUsername(),signupUserDTO.getPassphrase())){
            return ResponseEntity.status(HttpStatus.NOT_ACCEPTABLE).build();
        }
        String key = TOTPKeyGenerator.keyGenerator();
        String otpUri = String.format("otpauth://totp/%s:%s?secret=%s&issuer=%s", "Kerosene", signupUserDTO.getUsername(), key, "Kerosene");

        signupUserDTO.setTotpSecret(key);

        redisService.createTempUser(signupUserDTO);

        return ResponseEntity.ok(key);

    }
    @PostMapping("/totp/verify")
    public ResponseEntity<String> totpCodeVerify(@RequestBody SignupUserDTO signupUserDTO,HttpServletRequest request)  {

        if (!redisService.totpVerify(signupUserDTO)){
            return ResponseEntity.status(HttpStatus.NOT_ACCEPTABLE).build();
        }



        String deviceHash = request.getHeader("X-Device-Hash");


        if (!deviceHash.isEmpty() && !deviceHash.equalsIgnoreCase("unknown")){

            UserDataBase user = service.findByUsername(signupUserDTO.getUsername()).get();
            UserDevice device = new UserDevice();
            device.setUser(user);
            device.setDeviceHash(deviceHash);
            device.setIpAddress(ip.getIP(request));
            deviceService.create(device);

        }


        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

}
