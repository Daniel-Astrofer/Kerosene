package kerosene.v05.contracts;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;

public interface LoginVerifier {
    /*
    if the credentials send have match with the database return true
    */
    boolean Matcher(SignupUserDTO dto, HttpServletRequest request);
}
