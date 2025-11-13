package kerosene.v05.application.infra.persistance.jpa;

import kerosene.v05.model.entity.UserDataBase;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<UserDataBase,Long> {

    Optional<UserDataBase> findByUsername(String username);
    boolean existsByUsername(String username);
    boolean existsByUsernameAndPassphrase(String username,String passphrase);


}
