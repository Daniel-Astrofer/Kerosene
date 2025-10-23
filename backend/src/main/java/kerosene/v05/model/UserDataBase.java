package kerosene.v05.model;


import jakarta.persistence.*;
import kerosene.v05.contracts.UserDB;


@Entity()
@Table(schema = "auth", name = "users_credentials" )
public class UserDataBase implements UserDB {

    public UserDataBase() {
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    @Column(name = "username")
    private String username;

    @Column(name = "passphrase")
    private String passphrase;

    @Column(name = "totp_secret")
    private String totpSecret;

    @Override
    public String getTOTPSecret() {
        return totpSecret;
    }

    @Override
    public void setTOTPSecret(String totpSecret) {
        this.totpSecret = totpSecret;
    }

    @Override
    public String getUsername() {
        return username;
    }

    @Override
    public void setUsername(String username) {
        this.username = username;
    }

    @Override
    public void setPassphrase(String passphrase) {
        this.passphrase = passphrase;
    }

    @Override
    public String getPassphrase() {
        return passphrase;
    }

    @Override
    public long getId() {
        return this.id;
    }

}

