package kerosene.v05.repository;

import kerosene.v05.model.UserDataBase;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<UserDataBase,Long> {

    Optional<UserDataBase> findByUsername(String username);
    boolean existsByUsername(String username);
    boolean existsByUsernameAndPassphrase(String username,String passphrase);

}
