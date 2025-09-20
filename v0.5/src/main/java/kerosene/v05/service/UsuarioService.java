package kerosene.v05.service;

import kerosene.v05.Exceptions;
import kerosene.v05.contracts.Hasher;
import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;
import kerosene.v05.repository.UsuarioRepository;
import kerosene.v05.service.authentication.LoginValidator;
import kerosene.v05.service.validation.SignupValidator;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;




@Service
public class UsuarioService  {

    private final UsuarioRepository repository;

    public UsuarioService(UsuarioRepository repository){

        this.repository = repository;
    }

    public List<UserDataBase> listar() {
        return repository.findAll();
    }

    public Optional<UserDataBase> buscarPorId(Long id) {
        return repository.findById(id);
    }

    public void createUserInDataBase(UserDataBase user) {
        user.setUsername(user.getUsername().toLowerCase());
        repository.save(user);
    }

    public void deletar(Long id) {
        repository.deleteById(id);
    }

    public UserDataBase fromDTO(SignupUserDTO signupUserDTO){
        UserDataBase user = new UserDataBase();
        user.setPassphrase(signupUserDTO.getPassphrase().getBytes());
        user.setUsername(signupUserDTO.getUsername());

        return user;
    }



}
