package kerosene.v05.application.orchestrator.signup;

import kerosene.v05.application.orchestrator.login.contracts.Signup;
import kerosene.v05.application.service.cache.contracts.RedisService;
import kerosene.v05.application.service.validation.totp.contratcs.TOTPVerifier;
import kerosene.v05.dto.contracts.UserDTO;
import org.springframework.stereotype.Component;


@Component
public class SignupUseCase implements Signup {
    private final RedisService service;
    private final TOTPVerifier totp;
    public SignupUseCase(RedisService service, TOTPVerifier totp) {
        this.service = service;
        this.totp = totp;
    }

    @Override
    public void signupUser(UserDTO dto) {

        UserDTO user = service.getFromRedis(dto);
        totp.totpVerify(user.getTotpSecret(), dto.getTotpCode());


    }
}
