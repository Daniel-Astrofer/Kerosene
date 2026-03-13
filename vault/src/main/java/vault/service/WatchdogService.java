package vault.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import vault.security.VaultMemoryLocker;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReadWriteLock;
import java.util.concurrent.locks.ReentrantReadWriteLock;

/**
 * ─── O "WATCHDOG" (Cão de Guarda)
 * ──────────────────────────────────────────────
 *
 * Enquanto a Chave está trancada no Vault, ele ativamente verifica se os Shards
 * (Nós de Banco) estão vivos e sob o seu controle.
 *
 * Lógica Lockdown:
 * - Ping a cada 5 segundos na porta de consenso dos Shards.
 * - Se 1 Shard caiu, anota no log e chama API (AWS/GCP) da Infraestrutura
 * para iniciar Script de Ressurreição.
 * - Se 2 Shards caíram ou não respondem pela rede:
 * ⚠️ SOFT QUORUM LOCKDOWN ⚠️
 * O Vault para de aceitar novos nós ou provisionar chaves até que a rede
 * estabilize.
 * A chave permance intacta na RAM, evitando "Cascata de Pânico".
 */
@Service
public class WatchdogService {

    private static final Logger log = LoggerFactory.getLogger(WatchdogService.class);

    @Autowired
    private VaultMemoryLocker vaultLocker;

    // Controladores de estado dos Shards (ID Dinâmico -> Último Timestamp de
    // Resposta)
    private final ConcurrentHashMap<String, Long> activeShards = new ConcurrentHashMap<>();

    // Lock Atômico para prevenir Race Conditions durante o Lockdown
    private final ReadWriteLock lockdownLock = new ReentrantReadWriteLock();

    // Tempo Limite de Resposta (Tolerância Zero-Trust)
    private static final long MAX_MISS_TIME_MS = 15000; // 15 segundos sem heartbeat sinaliza queda

    // Flag de Soft Quorum (Bloqueia novos provisionamentos mas não mata o Vault)
    private volatile boolean isLockedDown = false;

    /**
     * Recebe o Beacon (Push) de um Shard autenticado
     */
    public void registerHeartbeat(String shardId) {
        lockdownLock.readLock().lock();
        try {
            activeShards.put(shardId, System.currentTimeMillis());
            if (isLockedDown) {
                // Tenta sair do lockdown se a rede parece estar voltando
                evaluateQuorumHealth();
            }
        } finally {
            lockdownLock.readLock().unlock();
        }
    }

    /**
     * O Scheduler agora apenas verifica o mapa em memória, sem bloquear threads com
     * IO de rede.
     */
    @Scheduled(fixedRate = 5000)
    public void executeHeartbeatCheck() {
        lockdownLock.writeLock().lock();
        try {
            evaluateQuorumHealth();
        } finally {
            lockdownLock.writeLock().unlock();
        }
    }

    private void evaluateQuorumHealth() {
        long now = System.currentTimeMillis();
        int liveNodesCount = 0;
        int deadNodesCount = 0;

        for (Map.Entry<String, Long> entry : activeShards.entrySet()) {
            if ((now - entry.getValue()) > MAX_MISS_TIME_MS) {
                deadNodesCount++;
                log.warn("[WATCHDOG] Shard {} missed heartbeat window.", entry.getKey());
            } else {
                liveNodesCount++;
            }
        }

        if (deadNodesCount >= 2 && !isLockedDown) {
            log.error("[CRITICAL] ⚠️ Quorum Loss Detected (2+ nodes down). Entering SOFT QUORUM LOCKDOWN.");
            enterSoftQuorumLockdown();
        } else if (isLockedDown && liveNodesCount >= 2) {
            log.info("[WATCHDOG] NETWORK RECOVERED. Soft Quorum restored. Exiting Lockdown Mode.");
            activeShards.clear(); // Reseta para evitar bounces
            isLockedDown = false;
        }
    }

    /**
     * Entra em estado de STALL (bloqueio), onde o Vault continua vivo com a chave
     * na RAM,
     * mas não responde a novos pedidos de /attest ou /provision até que a rede se
     * prove estável.
     */
    private void enterSoftQuorumLockdown() {
        this.isLockedDown = true;
        log.warn("[STALL] Vault is now locked down due to network quorum loss. Waiting for nodes to return...");
    }

    /**
     * Retorna o estado do Lock (Thread-Safe)
     */
    public boolean isLockedDown() {
        lockdownLock.readLock().lock();
        try {
            return isLockedDown;
        } finally {
            lockdownLock.readLock().unlock();
        }
    }
}
