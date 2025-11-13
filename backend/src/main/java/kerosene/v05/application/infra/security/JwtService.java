package kerosene.v05.application.infra.security;

public interface JwtService {
    String generateToken(long id , String devicehash );
    String extractDevice(String token);
    long extractId(String token);

}
