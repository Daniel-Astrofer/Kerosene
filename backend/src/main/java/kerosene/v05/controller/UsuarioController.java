package kerosene.v05.controller;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.application.orchestrator.login.contracts.Login;
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
   private final SignupVerifier signupVerifier;
   private final TOTPKeyGenerate TOTPKeyGenerator;
   private final UserServiceContract service;
   private final RedisService redisService;
   private final UserDeviceService deviceService;
   private final IP ip;
   private final JwtService jwt;
   private final TOTPVerifier totp;
   
    public UsuarioController(Login login,
                             SignupVerifier signupVerifier,
                             TOTPKeyGenerate totpKeyGenerator,
                             @Qualifier("ServiceFromUser") UserServiceContract service,
                             RedisService redisService, UserDeviceService deviceService,
                             @Qualifier("IPValidator") IP ip,
                             @Qualifier("JwtService") JwtService jwt,
                             TOTPVerifier totp1

    ) {
        this.login = login;


        this.signupVerifier = signupVerifier;
        TOTPKeyGenerator = totpKeyGenerator;
        this.service = service;
        this.redisService = redisService;
        this.deviceService = deviceService;
        this.ip = ip;
        this.jwt = jwt;

        this.totp = totp1;
    }

    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestBody UserDTO userDTO, HttpServletRequest request) {
        String id = login.loginUser(userDTO,request);
        return ResponseEntity.status(HttpStatus.ACCEPTED).body(id) ;
    }

    @PostMapping("/signup")
    public ResponseEntity<String> createUserInRedis(@RequestBody UserDTO userDTO, HttpServletRequest request){

        signupVerifier.verify(userDTO.getUsername(), userDTO.getPassphrase());
        String key = TOTPKeyGenerator.keyGenerator();
        String otpUri = String.format("otpauth://totp/%s:%s?secret=%s&issuer=%s", "Kerosene", userDTO.getUsername(), key, "Kerosene");

        userDTO.setTotpSecret(key);

        redisService.createTempUser(userDTO);

        return ResponseEntity.status(HttpStatus.ACCEPTED).body(key);

    }
    @PostMapping("/totp/verify")
    public ResponseEntity<String> totpCodeVerify(@RequestBody UserDTO userDTO, HttpServletRequest request)  {

        totp.totpVerify(userDTO);
        String deviceHash = request.getHeader("X-Device-Hash");
        String token = "";


        if (!deviceHash.isEmpty() && !deviceHash.equalsIgnoreCase("unknown")){

            UserDataBase user = service.findByUsername(userDTO.getUsername()).get();
            UserDevice device = new UserDevice();
            device.setUser(user);
            device.setDeviceHash(deviceHash);
            device.setIpAddress(ip.getIP(request));
            deviceService.create(device);
            token = jwt.generateToken(user.getId(),device.getDeviceHash());

        }


        return ResponseEntity.status(HttpStatus.ACCEPTED).body(token);
    }

}
