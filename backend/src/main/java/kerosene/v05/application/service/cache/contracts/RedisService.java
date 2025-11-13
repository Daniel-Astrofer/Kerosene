package kerosene.v05.application.service.cache.contracts;


import kerosene.v05.dto.contracts.UserDTO;


public interface RedisService {

   void createTempUser(UserDTO dto);
   UserDTO getFromRedis(UserDTO dto);
   void deleteFromRedis(UserDTO dto);
}
