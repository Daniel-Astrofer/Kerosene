package kerosene.v05.contracts;

import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;

public interface LoginVerifier {
    boolean checkUsername(String username);
    boolean passphraseMatcher(String username, String passphrase);
    boolean loginUser(SignupUserDTO user);
}
