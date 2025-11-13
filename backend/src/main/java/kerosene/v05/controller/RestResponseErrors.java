package kerosene.v05.controller;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.AuthExceptions;
import kerosene.v05.dto.ResponseError;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.time.LocalDateTime;

@ControllerAdvice
public class RestResponseErrors extends ResponseEntityExceptionHandler {

    @ExceptionHandler(AuthExceptions.UserAlreadyExistsException.class)
    public ResponseEntity<ResponseError> userAlredyExists(Exception ex,
                                                          HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(new ResponseError(
                LocalDateTime.now(),
                HttpStatus.CONFLICT,
                "User already exists",
                ex.getMessage(),
                request.getRequestURI()
        ));
    }
    @ExceptionHandler(AuthExceptions.UserNoExists.class)
    public ResponseEntity<ResponseError> userNoExists(Exception ex,
                                                          HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(new ResponseError(
                LocalDateTime.now(),
                HttpStatus.NOT_FOUND,
                "User no exists",
                ex.getMessage(),
                request.getRequestURI()
        ));
    }
    @ExceptionHandler(AuthExceptions.incorrectTotp.class)
    public ResponseEntity<ResponseError> incorretTotp(AuthExceptions.incorrectTotp ex,
                                                      HttpServletRequest request){
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(new ResponseError(
                LocalDateTime.now(),
                HttpStatus.FORBIDDEN,
                "Incorret TOTP",
                ex.getMessage(),
                request.getRequestURI()
        ));

    }

    @ExceptionHandler(AuthExceptions.InvalidCredentials.class)
    public ResponseEntity<ResponseError> invalidCredentials(AuthExceptions.InvalidCredentials ex,
                                                            HttpServletRequest request){
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(new ResponseError(
                LocalDateTime.now(),
                HttpStatus.UNAUTHORIZED,
                "Invalid Credentials",
                ex.getMessage(),
                request.getRequestURI()
        ));

    }
    @ExceptionHandler(AuthExceptions.UnrrecognizedDevice.class)
    public ResponseEntity<ResponseError> unrecognizedDevice(AuthExceptions.UnrrecognizedDevice ex,
                                                            HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).header("Next-Endpoint", "auth/totp/verify").body(
                new ResponseError(
                LocalDateTime.now(),
                HttpStatus.SEE_OTHER,
                "Unrecognized Device",
                ex.getMessage(),
                request.getRequestURI()
        ));
    }

}
