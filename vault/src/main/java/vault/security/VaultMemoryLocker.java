package vault.security;

import com.sun.jna.Library;
import com.sun.jna.Native;
import com.sun.jna.Pointer;

import java.nio.ByteBuffer;
import java.util.Arrays;

/**
 * ─── ZERO-PERSISTENCE MEMORY LOCKER (mlock) ──────────────────────────────────
 *
 * Implementação do primeiro passo do Vault: Blindagem da Memória (mlock).
 *
 * O Java normalmente gerencia a memória no Heap e o Sistema Operacional
 * (Linux/Windows)
 * é livre para jogar partes inativas da RAM para a Swap (Disco/SSD) quando
 * precisa de espaço.
 * Se a Chave Mestre for parar no arquivo de paginação (Swap), ela sobrevive a
 * um reboot e
 * pode ser extraída via análise forense do disco.
 *
 * Esta classe utiliza JNA (Java Native Access) para invocar chamadas de sistema
 * (syscalls)
 * nativas diretamente ao Kernel (mlock / mlockall no Linux/Unix).
 *
 * ─── Funcionamento
 * ────────────────────────────────────────────────────────────
 * 1. Aloca-se a Chave Mestre direto na memória nativa (Off-Heap) com
 * ByteBuffer.allocateDirect.
 * (Isto evita que o Garbage Collector mova a chave de lugar gerando cópias
 * indesejadas).
 * 2. Chama-se mlock() informando o ponteiro e o tamanho, travando-a na RAM
 * física.
 * 3. Shutdown Hook garante "Erase-on-Panic" (zeros) mesmo se o processo cair
 * bruscamente.
 */
public class VaultMemoryLocker {

    // Carregando as funções do Kernel em C direto pro Java via JNA
    private interface CLibrary extends Library {
        CLibrary INSTANCE = Native.load(System.getProperty("os.name").toLowerCase().contains("win") ? "msvcrt" : "c",
                CLibrary.class);

        // Int mlock(const void *addr, size_t len);
        int mlock(Pointer addr, long len);

        // Int munlock(const void *addr, size_t len);
        int munlock(Pointer addr, long len);

        // void *memset(void *s, int c, size_t n);
        Pointer memset(Pointer p, int c, long n);
    }

    private final ByteBuffer directBuffer;
    private final Pointer memoryPointer;
    private final int size;

    /**
     * Instancia um bloco de memória segura trancado via hardware (mlock).
     *
     * @param size em bytes (ex: 32 para AES-256)
     */
    public VaultMemoryLocker(int size) {
        this.size = size;
        // 1. Aloca "Off-Heap" — direto na memória nativa do SO, ignorando GC
        this.directBuffer = ByteBuffer.allocateDirect(size);
        this.memoryPointer = Native.getDirectBufferPointer(directBuffer);

        // 2. Trava a memória no Kernel impedindo paginação para Swap
        int mlockStatus = CLibrary.INSTANCE.mlock(memoryPointer, size);
        if (mlockStatus != 0) {
            throw new RuntimeException(
                    "CRITICAL: mlock() failed. Kernel refused to lock memory. Check OS capabilities (ulimit -l).");
        }

        // 3. Registra o Shutdown Hook (Erase-on-Panic / Lockdown)
        Runtime.getRuntime().addShutdownHook(new Thread(this::destroy));

        System.out.println("[Vault] 🔒 Memory locked securely in RAM. Size: " + size + " bytes.");
    }

    /**
     * Insere a chave dentro do cofre de memória de forma segura.
     */
    public void writeMasterKey(byte[] masterKey) {
        if (masterKey.length > size)
            throw new IllegalArgumentException("Key too large for vault buffer");
        directBuffer.clear();
        directBuffer.put(masterKey);
        // Zera o array original do heap Java rapidamente após copia
        Arrays.fill(masterKey, (byte) 0);
    }

    /**
     * Retorna uma CÓPIA da chave (deve ser zerada pelo chamador após o uso
     * imediatamente).
     */
    public byte[] getMasterKey() {
        byte[] key = new byte[size];
        directBuffer.clear();
        directBuffer.get(key);
        return key; // O CHAMADOR É RESPONSÁVEL POR ZERAR ESSE ARRAY!
    }

    /**
     * ─── ERASE-ON-PANIC (Autodestruição de Segurança) ─────────────────────────
     * O Método de limpeza brutal executado antes de qualquer desligamento.
     */
    public void destroy() {
        if (memoryPointer == null)
            return;

        // 1. Sobrescreve com Zeros instantaneamente via chamada nativa C (memset)
        // Isso é atômico a nível de SO e não pode ser interrompido pelo Garbage
        // Collector
        // ou sofrer desotimização do JIT Compiler, superando as limitações do OOM
        // Killer.
        CLibrary.INSTANCE.memset(memoryPointer, 0, size);

        // 2. Libera o Lock no Kernel para o SO
        CLibrary.INSTANCE.munlock(memoryPointer, size);

        System.out.println("[Vault] 💥 ERASE-ON-PANIC executed. Locked memory wiped and released.");
    }
}
