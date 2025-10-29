package kerosene.v05.controller;

import jakarta.servlet.http.HttpServletRequest;
import kerosene.v05.Exceptions;
import kerosene.v05.dto.ResponseError;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.time.LocalDateTime;

@ControllerAdvice
public class RestResponseErrors extends ResponseEntityExceptionHandler {

    @ExceptionHandler(Exceptions.UserAlreadyExistsException.class)
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
    @ExceptionHandler(Exceptions.UserNoExists.class)
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
    @ExceptionHandler
    public ResponseEntity<ResponseError> incorretTotp(Exception ex,
                                                      HttpServletRequest request){
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(new ResponseError(
                LocalDateTime.now(),
                HttpStatus.FORBIDDEN,
                "Incorret TOTP",
                ex.getMessage(),
                request.getRequestURI()
        ));

    }

}
