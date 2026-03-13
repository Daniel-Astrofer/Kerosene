package vault.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import vault.security.VaultMemoryLocker;

@Configuration
public class VaultConfig {

    private static final Logger log = LoggerFactory.getLogger(VaultConfig.class);

    // AES-256 (32 bytes)
    private static final int KEY_SIZE_BYTES = 32;

    @Bean
    public VaultMemoryLocker vaultMemoryLocker() {
        log.info("[VAULT] Booting Hardware Memory Locker ({} bytes off-heap)...", KEY_SIZE_BYTES);
        // Tenta adquirir o Lock no Kernel. Se o Linux negar privilégios de
        // IPC_LOCK/ulimit
        // ou o Server estiver sem memória, o Bean falha a inicialização fast-fail
        // (System.exit default).
        return new VaultMemoryLocker(KEY_SIZE_BYTES);
    }
}
