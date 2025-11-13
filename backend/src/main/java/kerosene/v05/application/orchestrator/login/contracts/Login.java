package kerosene.v05.application.orchestrator.login.contracts;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.dto.contracts.UserDTO;
import org.springframework.http.ResponseEntity;


public interface Login {

    String loginUser(UserDTO dto, HttpServletRequest request);

}
