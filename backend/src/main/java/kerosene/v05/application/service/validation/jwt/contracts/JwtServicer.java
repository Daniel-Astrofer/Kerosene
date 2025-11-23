package kerosene.v05.application.service.validation.jwt.contracts;

public interface JwtServicer {
    String generateToken(long id , String devicehash );
    String extractDevice(String token);
    long extractId(String token);

}
