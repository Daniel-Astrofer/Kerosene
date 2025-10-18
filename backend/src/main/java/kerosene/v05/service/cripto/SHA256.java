package kerosene.v05.service.cripto;

import kerosene.v05.contracts.Hasher;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.Base64;

@Component("SHAHasher")
public class SHA256 implements Hasher {

    /**
     * Encrypter
     *
     * @param  input receive the passphrase and encrypt
     * @throws RuntimeException when the algorithmic is invalid
     * @return return the hash of the passphrase
     */
    public String hash(String input) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(input.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    public Boolean verify(String passphrase, String hash) {
        String pass = hash(passphrase);
        return pass.equals(hash);
    }


}
