package kerosene.v05.service.validation;



import kerosene.v05.contracts.TOTPVerifier;
import org.jboss.aerogear.security.otp.Totp;
import org.springframework.stereotype.Service;


@Service
public class TOTPValidator implements TOTPVerifier {

    public boolean TOTPMatcher(String totpSecret,String code){

        Totp totp = new Totp(totpSecret);

        return totp.verify(code);

    }


}
