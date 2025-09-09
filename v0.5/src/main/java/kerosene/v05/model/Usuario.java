package kerosene.v05.model;


import jakarta.persistence.*;
import org.antlr.v4.runtime.misc.NotNull;
import org.hibernate.annotations.NotFound;

import java.time.LocalDateTime;


@Entity
@Table(name = "users_credentials")
public class Usuario {

    public Usuario() {
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    @Column(name  = "username")
    private String username;

    @Column(name = "passphrase")
    private String passphrase;


    public String getPassphrase() {
        return passphrase;
    }

    public void setPassphrase(String passphrase) {
        this.passphrase = passphrase;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String nome) {
        this.username = nome;
    }


}

