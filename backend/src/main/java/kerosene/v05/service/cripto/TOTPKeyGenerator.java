package kerosene.v05.service.cripto;

import kerosene.v05.contracts.TOTPKeyGenerate;
import org.jboss.aerogear.security.otp.api.Base32;
import org.springframework.stereotype.Component;

@Component
public class TOTPKeyGenerator implements TOTPKeyGenerate {

    @Override
    public String keyGenerator() {
        return Base32.random();

    }
}
