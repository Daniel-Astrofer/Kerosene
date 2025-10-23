package kerosene.v05.repository;

import kerosene.v05.model.UserDevice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


import java.util.Optional;


@Repository
public interface UserDeviceRepository extends JpaRepository<UserDevice, Long> {

    Optional<UserDevice> findById(long id);
    Optional<UserDevice> findByIdAndDeviceHash(long id,String deviceHash);



}
