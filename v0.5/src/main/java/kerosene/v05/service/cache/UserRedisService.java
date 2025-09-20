package kerosene.v05.service.cache;


import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import kerosene.v05.contracts.Cryptography;
import kerosene.v05.contracts.Hasher;
import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.service.UsuarioService;
import kerosene.v05.service.validation.TOTPValidator;
import org.springframework.stereotype.Service;
import org.springframework.data.redis.core.StringRedisTemplate;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.concurrent.TimeUnit;

@Service
public class UserRedisService {

    private final static String keybase = "w4K+9Vx3y6dR1P8h2mYtB3vQjL6uXk7nZq5sF0aV8pU=";
    static final byte[] decodedKey = Base64.getDecoder().decode(keybase);
    static final SecretKeySpec secretKey = new SecretKeySpec(decodedKey,"AES");
    private final StringRedisTemplate redisTemplate;
    private final ObjectMapper objectMapper;
    private final Cryptography cryptography;
    private final TOTPValidator TOTPValidator;
    private final UsuarioService service;
    private final Hasher hasher;

    public UserRedisService(StringRedisTemplate redisTemplate, Cryptography cryptography,
                            TOTPValidator TOTPValidator,
                            UsuarioService service, Hasher hasher) {
        this.redisTemplate = redisTemplate;
        this.cryptography = cryptography;
        this.TOTPValidator = TOTPValidator;
        this.service = service;
        this.hasher = hasher;
        this.objectMapper = new ObjectMapper();

    }



    public void createTempUser(SignupUserDTO signupUserDTO){

        byte[] passByte = Base64.getEncoder().encode(signupUserDTO.getPassphrase().getBytes());
        String hashPassString = Base64.getEncoder().encodeToString(hasher.hash(passByte));

        String totpSecret = signupUserDTO.getTotp_secret();

        try{


            signupUserDTO.setPassphrase(hashPassString);
            byte[] encriptedTotp = cryptography.encrypt(signupUserDTO.getTotp_secret().getBytes(),secretKey);
            String totpString = Base64.getEncoder().encodeToString(encriptedTotp);
            signupUserDTO.setTotp_secret(totpString);

            String json = objectMapper.writeValueAsString(signupUserDTO);

            redisTemplate.opsForValue().set("signup:" + signupUserDTO.getUsername(),json,10, TimeUnit.MINUTES);

        }catch (Exception e){e.printStackTrace();}

    }

    public String getFromRedis( String key) {
        return redisTemplate.opsForValue().get(key);
    }

    public SignupUserDTO jsonToUserDTO(String key, String username ){
        String json =  getFromRedis(key + username);
        try{
            return objectMapper.readValue(json, SignupUserDTO.class);
        }catch (JsonProcessingException e ){
            e.printStackTrace();
        }
        return null;
    }

    public byte[] totpDecoder(SignupUserDTO signupUserDTO){
        return  Base64.getDecoder().decode(signupUserDTO.getTotp_secret());
    }


    public String totpDecryptedString(SignupUserDTO signupUserDTO, SecretKey keybase){

        try{
            byte[] totp = cryptography.decrypt(totpDecoder(signupUserDTO),keybase);
            return new String(totp,StandardCharsets.UTF_8);
        }catch (Exception e){
            e.printStackTrace();
        }return null;
    }

    public Boolean totpVerify(SignupUserDTO signupUserDTO){


        try {

            SignupUserDTO usuario = jsonToUserDTO("signup:", signupUserDTO.getUsername());

            String totpDecodedString = totpDecryptedString(usuario,secretKey);

            if (TOTPValidator.totpMatcher(totpDecodedString,usuario.getTot_code())){
                Usuario usuarioDB = service.fromDTO(usuario);
                usuarioDB.setTot_secret(signupUserDTO.getTotp_secret().getBytes());
                service.createUser(usuarioDB);
                return true;

            }
        }catch(Exception e){
            e.printStackTrace();
        }return false;

    }

}
