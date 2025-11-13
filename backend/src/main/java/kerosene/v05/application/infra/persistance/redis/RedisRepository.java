package kerosene.v05.application.infra.persistance.redis;

import kerosene.v05.dto.contracts.UserDTO;

import java.time.Duration;


public interface RedisRepository{

    void save(String key, UserDTO dto, long expirationInMinutes);
    UserDTO find(String key,UserDTO dto);
    void delete(String key,UserDTO dto);


}
