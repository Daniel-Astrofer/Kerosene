package kerosene.v05.application.service.validation.totp;



import kerosene.v05.AuthExceptions;
import kerosene.v05.application.service.cache.contracts.RedisService;
import kerosene.v05.application.service.cripto.contracts.Cryptography;
import kerosene.v05.application.service.validation.totp.contratcs.TOTPVerifier;
import kerosene.v05.dto.contracts.UserDTO;
import org.jboss.aerogear.security.otp.Totp;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Base64;


@Service
public class TOTPValidator implements TOTPVerifier {

    @Value("${api.secret.aes.secret}")
    private SecretKey secretKey;
    private final RedisService service;

    private final Cryptography cryptography ;

    public TOTPValidator(RedisService service,
                         @Qualifier("aes256") Cryptography cryptography) {
        this.service = service;
        this.cryptography = cryptography;
    }

    @Override
    public boolean totpMatcher(String totpSecret,String code){

        Totp totp = new Totp(totpSecret);
        return totp.verify(code);

    }
    @Override
    public String totpDecryptedToString(String totpSecret, SecretKey secretKey){
        byte[] totpCoded =  Base64.getDecoder().decode(totpSecret);
        try{
            byte[] totp = cryptography.decrypt(totpCoded,secretKey);
            return new String(totp, StandardCharsets.UTF_8);
        }catch (Exception e){
            throw new RuntimeException("Decryption error: " );
        }
    }

    @Override
    public void totpVerify(String totpSecret,String totpCode){

        /*UserDTO usuario = service.getFromRedis(userDTO); */
        String totp = totpDecryptedToString(totpSecret,secretKey);

        if (!totpMatcher(totp, totpCode)){
            throw new AuthExceptions.incorrectTotp("Incorrect TOTP code");
        }

    }


}
