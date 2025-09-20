package kerosene.v05.contracts;

import javax.crypto.SecretKey;

public interface Cryptography {
    byte[] encrypt(byte [] encrypt, SecretKey key) throws Exception;
    byte[] decrypt(byte[] encrypted, SecretKey key) throws Exception;
}
