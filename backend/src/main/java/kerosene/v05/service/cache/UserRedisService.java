package kerosene.v05.service.cache;


import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import kerosene.v05.contracts.Cryptography;
import kerosene.v05.contracts.Hasher;
import kerosene.v05.contracts.RedisService;
import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;
import kerosene.v05.service.UsuarioService;
import kerosene.v05.service.validation.TOTPValidator;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.data.redis.core.StringRedisTemplate;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.concurrent.TimeUnit;
import org.jboss.aerogear.security.otp.api.Base32;

@Service
public class UserRedisService implements RedisService {

    private final static String keybase = "w4K+9Vx3y6dR1P8h2mYtB3vQjL6uXk7nZq5sF0aV8pU=";
    static final byte[] decodedKey = Base64.getDecoder().decode(keybase);
    static final SecretKeySpec secretKey = new SecretKeySpec(decodedKey,"AES");
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;
    private final Cryptography cryptography;
    private final TOTPValidator TOTPValidator;
    private final UsuarioService service;
    private final Hasher hasher;

    public UserRedisService(StringRedisTemplate redisTemplate,
                            @Qualifier("aes256") Cryptography cryptography,
                            TOTPValidator TOTPValidator,
                            UsuarioService service,
                            @Qualifier("SHAHasher") Hasher hasher) {
        this.redisTemplate = redisTemplate;
        this.cryptography = cryptography;
        this.TOTPValidator = TOTPValidator;
        this.service = service;
        this.hasher = hasher;
        this.objectMapper = new ObjectMapper();

    }



    public void createTempUser(SignupUserDTO signupUserDTO){

        String hashPassString = hasher.hash(signupUserDTO.getPassphrase());

        String totpSecret = signupUserDTO.getTotpSecret();

        try{

            signupUserDTO.setPassphrase(hashPassString);
            byte[] encriptedTotpSecret = cryptography.encrypt(totpSecret.getBytes(StandardCharsets.UTF_8),secretKey);

            String base64 = Base64.getEncoder().encodeToString(encriptedTotpSecret);

            signupUserDTO.setTotpSecret(base64);

            String json = objectMapper.writeValueAsString(signupUserDTO);

            redisTemplate.opsForValue().set("signup:" + signupUserDTO.getUsername(),json,10, TimeUnit.MINUTES);

        }catch (Exception e){e.printStackTrace();}

    }

    public String getFromRedis(String key) {
        return redisTemplate.opsForValue().get(key);
    }

    public SignupUserDTO jsonToSignupUserDTO(String key, String username ){
        String json =  getFromRedis(key + username);
        try{
            return objectMapper.readValue(json, SignupUserDTO.class);
        }catch (JsonProcessingException e ){
            e.printStackTrace();
        }
        return null;
    }


    public String TOTPDecryptedToString(SignupUserDTO signupUserDTO, SecretKey keybase){

        byte[] totpCoded =  Base64.getDecoder().decode(signupUserDTO.getTotpSecret());
        try{
            byte[] totp = cryptography.decrypt(totpCoded,keybase);
            return new String(totp,StandardCharsets.UTF_8);
        }catch (Exception e){
            e.printStackTrace();
        }return null;
    }

    public Boolean totpVerify(SignupUserDTO signupUserDTO){

        try {

            SignupUserDTO usuario = jsonToSignupUserDTO("signup:", signupUserDTO.getUsername());

            String totpDecodedString = TOTPDecryptedToString(usuario,secretKey);

            if (TOTPValidator.TOTPMatcher(totpDecodedString,signupUserDTO.getTotpCode())){
                UserDataBase user = service.fromDTO(usuario);
                user.setTOTPSecret(usuario.getTotpSecret());
                service.createUserInDataBase(user);
                return true;

            }
        }catch(Exception e){

            e.printStackTrace();
        }return false;

    }

}
