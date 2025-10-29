package kerosene.v05.service;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.contracts.Hasher;
import kerosene.v05.contracts.IP;
import kerosene.v05.contracts.UserDB;
import kerosene.v05.dto.SignupUserDTO;
import kerosene.v05.model.UserDataBase;
import kerosene.v05.model.UserDevice;
import kerosene.v05.repository.UsuarioRepository;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.util.Assert;

import java.lang.reflect.Field;
import java.util.Optional;

@SpringBootTest
@ExtendWith(MockitoExtension.class)
class LoginValidatorTest {

    @InjectMocks
    private kerosene.v05.service.authentication.LoginValidator validator;


    @Mock
    private UsuarioRepository repository;

    private SignupUserDTO user;

    private UserDevice device;
    @Mock
    private Hasher hasher;
    @Mock
    private IP ip;

    @Mock
    private HttpServletRequest request;

    @BeforeEach
    void setUp(){
        user = new SignupUserDTO();
        user.setUsername("testuser");
        user.setPassphrase("hashedpass");
        user.setTotpSecret("secretkey");
        ReflectionTestUtils.setField(user,"id",1L);

        device = new UserDevice();
        device.setDeviceHash("devicehash");
        device.setIpAddress(ip.getIP(request));
    }



    @Test
    public void Matcher(){

        ReflectionTestUtils.setField(user,"id",1L);

        Mockito.when(ip.getIP(request)).thenReturn("192.1682.0.0");

        boolean result = validator.Matcher(user,request);

        Assertions.assertTrue(result);



    }





}