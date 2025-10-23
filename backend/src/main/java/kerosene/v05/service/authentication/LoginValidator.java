package kerosene.v05.service.authentication;

import kerosene.v05.Exceptions;

import kerosene.v05.contracts.Hasher;
import kerosene.v05.contracts.LoginVerifier;
import kerosene.v05.contracts.SignupVerifier;
import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;
import kerosene.v05.repository.UsuarioRepository;
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

    public LoginValidator(UsuarioRepository repository,
                          @Qualifier("SHAHasher") Hasher hasher
    ) {
        this.repository = repository;
        this.hasher = hasher;
    }

    @Override
    public boolean checkUsername(String username) throws Exceptions.UserNoExists{
        return repository.findByUsername(username).isPresent();
    }
    @Override
    public boolean passphraseMatcher(String username,String passphrase)throws Exceptions.InvalidPassphrase {

        return repository.existsByUsernameAndPassphrase(
                username,
                passphrase
        );
    }

    public boolean loginUser(SignupUserDTO user) {

        String username = user.getUsername();
        String passphrase = hasher.hash(user.getPassphrase());
        try {
            return checkUsername(username) && passphraseMatcher(username, passphrase);
        } catch (Exceptions.UserNoExists | Exceptions.InvalidPassphrase e ) {
            return false;
        }
    }




}