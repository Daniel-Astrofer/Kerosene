package kerosene.v05.service.authentication;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.Exceptions;

import kerosene.v05.contracts.Hasher;
import kerosene.v05.contracts.IP;
import kerosene.v05.contracts.LoginVerifier;
import kerosene.v05.contracts.SignupVerifier;
import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;
import kerosene.v05.model.UserDevice;
import kerosene.v05.repository.UsuarioRepository;
import kerosene.v05.service.UserDeviceService;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

/**
 * Service responsible for authenticating users.
 * It checks if the username exists and if the passphrase is valid.
 */
@Service
public class LoginValidator implements LoginVerifier {

    private final UsuarioRepository repository;
    private final Hasher hasher;
    private final IP ip;
    private final UserDeviceService deviceService;

    public LoginValidator(UsuarioRepository repository,
                          @Qualifier("SHAHasher") Hasher hasher,
                          @Qualifier("IPValidator") IP ip,
                          UserDeviceService deviceService
    ) {
        this.repository = repository;
        this.hasher = hasher;
        this.ip = ip;
        this.deviceService = deviceService;
    }





    public boolean Matcher(SignupUserDTO user, HttpServletRequest request){

        String username = user.getUsername();
        String passphrase = hasher.hash(user.getPassphrase());

            if (repository.existsByUsernameAndPassphrase(username,passphrase)){

                UserDataBase person = repository.findByUsername(username).get();
                long clientId = person.getId();
                String requestIp = ip.getIP(request);

                UserDevice device = deviceService.find(clientId).get();
                String clientIp = device.getIpAddress();
                String clientDeviceHash = device.getDeviceHash();
                String requestDeviceHash  = ip.getDeviceHash(request);

                return requestIp.equals(clientIp) && requestDeviceHash.equals(clientDeviceHash);


            } return false;




    }


}