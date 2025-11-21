package kerosene.v05.service;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.application.infra.persistance.jpa.UserRepository;
import kerosene.v05.application.orchestrator.login.LoginUseCase;
import kerosene.v05.application.service.authentication.LoginValidator;
import kerosene.v05.application.service.authentication.contracts.LoginVerifier;
import kerosene.v05.application.service.cripto.hasher.BcriptHasher;
import kerosene.v05.application.service.device.UserDeviceService;
import kerosene.v05.application.service.validation.ip_handler.IPValidator;
import kerosene.v05.application.service.validation.ip_handler.contracts.IP;
import kerosene.v05.dto.UserDTO;
import kerosene.v05.model.entity.UserDataBase;
import kerosene.v05.model.entity.UserDevice;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Optional;

import static org.mockito.Mockito.*;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class LoginValidatorTest {

    @Mock
    private HttpServletRequest request;

    @InjectMocks
    private LoginValidator verifier;

    @Mock
    private UserRepository repository;

    @Mock
    private BcriptHasher hash;

    @Mock
    private IP ip;

    @Mock
    private UserDeviceService device;

    @Mock
    private LoginUseCase login;



    @Test
    void should_call_matcher_when_no_jwtToken_send(){

            UserDTO dto = new UserDTO();
            dto.setUsername("user");
            dto.setPassphrase("test");

            UserDataBase db = new UserDataBase();
            db.setUsername("user");
            db.setPassphrase("test");
            ReflectionTestUtils.setField(db,"id",1L);

            UserDevice userDevice = new UserDevice();
            userDevice.setUser(db);
            userDevice.setDeviceHash("ABA");
            userDevice.setIpAddress("123");
            ReflectionTestUtils.setField(userDevice,"id",1L);


            when(repository.findByUsername("user")).thenReturn(Optional.of(db));
            when(device.find(db.getId())).thenReturn(Optional.of(userDevice));
            when(ip.getDeviceHash(request)).thenReturn("ABA");
            when(ip.getIP(request)).thenReturn("123");


            Assertions.assertEquals(db,verifier.matcher(dto,request));



    }


}
