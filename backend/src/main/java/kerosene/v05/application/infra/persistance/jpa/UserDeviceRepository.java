package kerosene.v05.application.infra.persistance.jpa;

import kerosene.v05.model.entity.UserDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


import java.util.Optional;


@Repository
public interface UserDeviceRepository extends JpaRepository<UserDevice, Long> {

    Optional<UserDevice> findByUserId(long id);
    Optional<UserDevice> findByIdAndDeviceHash(long id,String deviceHash);

}
