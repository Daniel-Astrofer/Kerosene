package kerosene.v05.application.service.cripto.encrypter;


import kerosene.v05.application.service.cripto.contracts.Hasher;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component("BcryptHasher")
public class BcriptHasher implements Hasher {

    @Override
    public String hash(String passphrase) {
        PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
        return passwordEncoder.encode(passphrase);
    }
    @Override
    public Boolean verify(String passphrase,String hash){
        PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
        return passwordEncoder.matches(passphrase,hash);

    }

}
