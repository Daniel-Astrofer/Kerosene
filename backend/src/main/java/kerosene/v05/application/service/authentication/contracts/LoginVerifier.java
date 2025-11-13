package kerosene.v05.application.service.authentication.contracts;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.dto.contracts.UserDTO;
import kerosene.v05.model.contracts.UserDB;

public interface LoginVerifier {

    UserDB matcher(UserDTO dto, HttpServletRequest request);
}
