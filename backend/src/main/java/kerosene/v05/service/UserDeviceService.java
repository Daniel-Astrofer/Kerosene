package kerosene.v05.service;



import kerosene.v05.model.UserDevice;
import kerosene.v05.repository.UserDeviceRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class UserDeviceService {

    private final UserDeviceRepository deviceRepository;

    public UserDeviceService(UserDeviceRepository deviceRepository){

        this.deviceRepository = deviceRepository;

    }


    public void create(UserDevice userDevice){

        deviceRepository.save(userDevice);

    }

    public boolean delete(UserDevice userDevice){

        if (deviceRepository.findByIdAndDeviceHash(userDevice.getId(),userDevice.getDeviceHash()).isPresent()){
            deviceRepository.delete(userDevice);
            return true;
        }return false;


    }

    public boolean update(long userId,UserDevice userDevice){
        Optional<UserDevice> user = deviceRepository.findById(userId) ;

        if (user.isPresent()){

             deviceRepository.delete(user.get());
             deviceRepository.save(userDevice);
             return true;
        }return false;

    }








}
