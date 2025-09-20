package kerosene.v05;

public class Exceptions {


    public static class AuthValidationException extends RuntimeException{
        public AuthValidationException(String message){
            super(message);
        }
    }

        public static class UserAlreadyExistsException extends AuthValidationException {
            public UserAlreadyExistsException(String message) {
                super(message);
            }
        }

        public static class UsernameCantBeNull extends AuthValidationException {
            public UsernameCantBeNull(String message) {
                super(message);
            }
        }

        public static class PassphraseCantBeNull extends AuthValidationException {
            public PassphraseCantBeNull(String message) {
                super(message);
            }
        }

        public static class InvalidCharacterUsername extends AuthValidationException{
            public InvalidCharacterUsername(String message){
                super(message);
            }
        }

        public static class UsernameCharacterLimitException extends AuthValidationException {
            public UsernameCharacterLimitException(String message){
                super(message);
            }
        }

        public static class UserNoExists extends AuthValidationException{
            public UserNoExists(String message){
                super(message);
            }
        }
        public static class InvalidPassphrase extends AuthValidationException{
            public InvalidPassphrase(String message){
                super(message);
            }
        }





}
