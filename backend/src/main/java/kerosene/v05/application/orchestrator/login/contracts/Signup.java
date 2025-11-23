package kerosene.v05.application.orchestrator.login.contracts;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.dto.UserDTO;

public interface Signup {



    String signupUser(UserDTO dto);

    String createUser(UserDTO dto,
                    HttpServletRequest request);
}
