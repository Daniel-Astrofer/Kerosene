package kerosene.v05.application.service.user;

import kerosene.v05.application.service.user.contract.UserServiceContract;
import kerosene.v05.dto.UserDTO;
import kerosene.v05.model.entity.UserDataBase;
import kerosene.v05.application.infra.persistance.jpa.UserRepository;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;




@Service("ServiceFromUser")
public class UserService implements UserServiceContract {

    private final UserRepository repository;

    public UserService(UserRepository repository){

        this.repository = repository;
    }

    public List<UserDataBase> listar() {
        return repository.findAll();
    }

    public Optional<UserDataBase> buscarPorId(Long id) {
        return repository.findById(id);
    }

    public Optional<UserDataBase> findByUsername(String username) {

        return repository.findByUsername(username);
    }

    public void createUserInDataBase(UserDataBase user) {
        user.setUsername(user.getUsername().toLowerCase());
        repository.save(user);
    }

    public void deletar(Long id) {
        repository.deleteById(id);
    }

    public UserDataBase fromDTO(UserDTO userDTO){
        UserDataBase user = new UserDataBase();
        user.setPassphrase(userDTO.getPassphrase());
        user.setUsername(userDTO.getUsername());

        return user;
    }



}
