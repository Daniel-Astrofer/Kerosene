package kerosene.v05.service.validation;

import kerosene.v05.Exceptions;
import kerosene.v05.contracts.SignupVerifier;
import kerosene.v05.repository.UsuarioRepository;
import org.springframework.stereotype.Component;
import org.bitcoinj.crypto.MnemonicCode;
import org.bitcoinj.crypto.MnemonicException;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;

/**
 * Service for verifying user credentials.
 * Checks username and passphrase for validity, format, length, and existence.
 */
@Service
public class SignupValidator implements SignupVerifier {

    private static final int USERNAME_CHARACTER_LIMIT = 50;
    private static final int PASSPHRASE_CHARACTER_MAX_LIMIT = 161;

    private final UsuarioRepository repository;


    public SignupValidator(UsuarioRepository repository) {
        this.repository = repository;
    }


    @Override
    public void checkUsernameNotNull(String username) {
        if (username== null || username.isBlank()) {
            throw new Exceptions.UsernameCantBeNull("Username cannot be null");
        }
    }
    @Override
    public void checkPassphraseNotNull(String passphrase) {
        if ( passphrase == null ) {
            throw new Exceptions.PassphraseCantBeNull("Passphrase cannot be null");
        }
    }
    @Override
    public void checkUsernameFormat(String username) {
        if (!username.matches("^[a-zA-Z0-9_]+$")) {
            throw new Exceptions.InvalidCharacterUsername("Invalid character in username");
        }
    }
    @Override
    public void checkUsernameLength(String username) {
        if (username.length() > USERNAME_CHARACTER_LIMIT) {
            throw new Exceptions.UsernameCharacterLimitException("Username character limit exceeded");
        }
    }
    @Override
    public void checkPassphraseLength(String passphrase) {
        if (passphrase.length() > PASSPHRASE_CHARACTER_MAX_LIMIT) {
            throw new Exceptions.UsernameCharacterLimitException("Passphrase character limit exceeded");
        }
    }
    @Override
    public void checkPassphraseBip39(String passphrase) {
        String phrase = passphrase.trim().replaceAll("[\\s\\u00A0]+", " ");
        List<String> words = Arrays.asList(phrase.split(" "));

        try {
            MnemonicCode.INSTANCE.check(words);
        } catch (MnemonicException.MnemonicWordException e) {
            throw new Exceptions.InvalidPassphrase("Unrecognized word in passphrase");
        } catch (MnemonicException.MnemonicLengthException e) {
            throw new Exceptions.InvalidPassphrase("Passphrase length incompatible with BIP39");
        } catch (MnemonicException e) {
            throw new Exceptions.InvalidPassphrase("Invalid passphrase");
        }
    }
    @Override
    public void checkUsernameExists(String username) {
        if (repository.findByUsername(username) != null) {
            throw new Exceptions.UserAlreadyExistsException("User already exists");
        }
    }
    public boolean verify(String username,String passphrase) {

        checkUsernameNotNull(username);
        checkPassphraseNotNull(passphrase);
        checkUsernameFormat(username);
        checkUsernameLength(username);
        checkPassphraseLength(passphrase);
        checkPassphraseBip39(passphrase);
        checkUsernameExists(username);

        return true;
    }

}
