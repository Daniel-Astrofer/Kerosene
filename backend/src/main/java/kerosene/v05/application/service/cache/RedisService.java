package kerosene.v05.application.service.cache;


import kerosene.v05.application.infra.persistance.redis.RedisRepository;
import kerosene.v05.application.service.cripto.contracts.Cryptography;
import kerosene.v05.application.service.cripto.contracts.Hasher;
import kerosene.v05.dto.contracts.UserDTO;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;


@Service
public class RedisService implements kerosene.v05.application.service.cache.contracts.RedisService {

    @Value("${api.secret.aes.secret}")
    private static String keybase;
    static final byte[] decodedKey = Base64.getDecoder().decode(keybase);
    static final SecretKeySpec secretKey = new SecretKeySpec(decodedKey,"AES");

    private final Cryptography cryptography;
    private final RedisRepository repository;
    private final Hasher hasher;
    private static final String key = "signup:" ;

    public RedisService(RedisRepository repository,
                        @Qualifier("aes256") Cryptography cryptography,
                        @Qualifier("Bcrypt") Hasher hasher)
    {
        this.repository = repository;
        this.cryptography = cryptography;
        this.hasher = hasher;
    }

    @Override
    public void createTempUser(UserDTO userDTO){

        userDTO.setPassphrase(
                hasher.hash(userDTO.getPassphrase()));

        try{
            String base64 = Base64.getEncoder()
                    .encodeToString(
                            cryptography.encrypt(userDTO.getTotpSecret()
                                    .getBytes(StandardCharsets.UTF_8), secretKey));
            userDTO.setTotpSecret(base64);

        }catch (Exception e){
            throw new RuntimeException("Error encrypting TOTP secret");
        }repository.save(key, userDTO,120);

    }

    @Override
    public UserDTO getFromRedis(UserDTO dto) {
        return repository.find(key, dto);
    }

    @Override
    public void deleteFromRedis(UserDTO dto) {
        repository.delete(key, dto);
    }


}
