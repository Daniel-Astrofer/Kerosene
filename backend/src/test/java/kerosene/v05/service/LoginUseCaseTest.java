package kerosene.v05.service;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.application.infra.persistance.jpa.UserRepository;
import kerosene.v05.application.orchestrator.login.LoginUseCase;
import kerosene.v05.application.service.authentication.LoginValidator;
import kerosene.v05.application.service.authentication.contracts.LoginVerifier;
import kerosene.v05.application.service.device.UserDeviceService;
import kerosene.v05.dto.UserDTO;
import kerosene.v05.model.entity.UserDataBase;
import kerosene.v05.model.entity.UserDevice;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.DisplayName;
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

@ExtendWith(MockitoExtension.class)
class LoginUseCaseTest {


    @Mock
    HttpServletRequest request;

    @Mock
    LoginVerifier verifier;

    @Mock
    private UserRepository repository;

    @Mock
    UserDeviceService device;

    @InjectMocks
    private LoginUseCase login;

    @Test
    @DisplayName("should return id when user send jwt token")
    void should_return_id_when_jwtToken_send(){

        try(MockedStatic<SecurityContextHolder> se  = mockStatic(SecurityContextHolder.class) ){
            Authentication auth = mock(Authentication.class);
            SecurityContext context = mock(SecurityContext.class);

            when(context.getAuthentication()).thenReturn(auth);
            se.when(SecurityContextHolder::getContext).thenReturn(context);
            when(auth.getName()).thenReturn("1");


            UserDTO dto = new UserDTO();
            Assertions.assertEquals("1",login.loginUser(dto,request));
        }


    }


}

