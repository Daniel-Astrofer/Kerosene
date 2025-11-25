package kerosene.v05.application.orchestrator.signup;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.AuthExceptions;
import kerosene.v05.application.service.validation.jwt.contracts.JwtServicer;
import kerosene.v05.application.orchestrator.login.contracts.Signup;
import kerosene.v05.application.service.authentication.contracts.SignupVerifier;
import kerosene.v05.application.service.cache.contracts.RedisService;
import kerosene.v05.application.service.device.UserDeviceService;
import kerosene.v05.application.service.user.contract.UserServiceContract;
import kerosene.v05.application.service.validation.ip_handler.contracts.IP;
import kerosene.v05.application.service.validation.totp.contratcs.TOTPKeyGenerate;
import kerosene.v05.dto.UserDTO;
import kerosene.v05.model.entity.UserDataBase;
import kerosene.v05.model.entity.UserDevice;
import org.springframework.stereotype.Component;


@Component
public class SignupUseCase implements Signup {
    private final RedisService cacheService;
    private final TOTPKeyGenerate totpGenerator;
    private final SignupVerifier verifier;
    private final RedisService cache;
    private final UserServiceContract userService;
    private final UserDeviceService deviceService;
    private final IP ip;
    private final JwtServicer jwt;
    public SignupUseCase(RedisService cacheService,
                         TOTPKeyGenerate totpGenerator,
                         SignupVerifier verifier,
                         RedisService cache,
                         UserServiceContract userService,
                         UserDeviceService deviceService,
                         IP ip,
                         JwtServicer jwt) {
        this.cacheService = cacheService;
        this.totpGenerator = totpGenerator;
        this.verifier = verifier;
        this.cache = cache;
        this.userService = userService;
        this.deviceService = deviceService;
        this.ip = ip;
        this.jwt = jwt;
    }

    @Override
    public String signupUser(UserDTO dto) {
        dto.setUsername(dto.getUsername().toLowerCase());
        verifier.verify(dto.getUsername(), dto.getPassphrase());
        String key = totpGenerator.keyGenerator();
        String otpUri = String.format("otpauth://totp/%s:%s?secret=%s&issuer=%s", "Kerosene", dto.getUsername(), key, "Kerosene");
        dto.setTotpSecret(key);
        cacheService.createTempUser(dto);
        return otpUri;

    }
    @Override
    public String createUser(UserDTO dto,
                           HttpServletRequest request){
        UserDTO user = cache.getFromRedis(dto);
        if (user == null){
            throw new AuthExceptions.TotpTimeExceded("account is no more available,signup again");
        }
        String deviceHash = request.getHeader("X-Device-Hash");
        if (deviceHash.isEmpty() || deviceHash.equalsIgnoreCase("unknown")){
            throw new AuthExceptions.UnrrecognizedDevice("device not recognized");
        }

            UserDataBase userDB = userService.fromDTO(user);
            userService.createUserInDataBase(userDB);

            UserDevice device = new UserDevice();
            device.setUser(userDB);
            device.setDeviceHash(deviceHash);
            device.setIpAddress(ip.getIP(request));
            deviceService.create(device);
            cache.deleteFromRedis(user);

        return jwt.generateToken(userDB.getId(),device.getDeviceHash());

    }
}
