package kerosene.v05.application.service.validation.totp;

import kerosene.v05.application.service.validation.totp.contratcs.TOTPKeyGenerate;
import org.jboss.aerogear.security.otp.api.Base32;
import org.springframework.stereotype.Component;

@Component
public class TOTPKeyGenerator implements TOTPKeyGenerate {

    @Override
    public String keyGenerator() {
        return Base32.random();
    }
}
