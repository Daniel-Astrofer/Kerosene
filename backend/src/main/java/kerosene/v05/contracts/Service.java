package kerosene.v05.contracts;

import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;

import java.util.List;
import java.util.Optional;

public interface Service {

    List<UserDataBase> listar();
    Optional<UserDataBase> buscarPorId(Long id);
    void createUserInDataBase(UserDataBase user);
    void deletar(Long id);
    UserDataBase fromDTO(SignupUserDTO signupUserDTO);
}
