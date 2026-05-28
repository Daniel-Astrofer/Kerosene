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
    private final ConcurrentHashMap<String, Long> lastRecoveryAttempts = new ConcurrentHashMap<>();

    // Lock Atômico para prevenir Race Conditions durante o Lockdown
    private final ReadWriteLock lockdownLock = new ReentrantReadWriteLock();

    // Tempo Limite de Resposta (Tolerância Zero-Trust)
    private static final long MAX_MISS_TIME_MS = 120000; // 2 minutos para tolerar latência extrema do Tor
    private static final long RECOVERY_ATTEMPT_INTERVAL_MS = 60000;
    private static final long STALE_SHARD_EVICT_MS = 300000;
    private static final int REQUIRED_LIVE_QUORUM = 2;

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
            long shardAgeMs = now - entry.getValue();
            if (shardAgeMs > STALE_SHARD_EVICT_MS) {
                deadNodesCount++;
                activeShards.remove(entry.getKey(), entry.getValue());
                lastRecoveryAttempts.remove(entry.getKey());
                log.warn("[WATCHDOG] Shard {} remained stale for {}ms. Evicting from active watchdog set.",
                        entry.getKey(), shardAgeMs);
            } else if (shardAgeMs > MAX_MISS_TIME_MS) {
                deadNodesCount++;
                maybeTriggerInfrastructureRecovery(entry.getKey(), now);
            } else {
                liveNodesCount++;
            }
        }

        // Prioritize current live quorum over stale dead entries so rolling restarts
        // do not permanently poison the watchdog state.
        if (isLockedDown && liveNodesCount >= REQUIRED_LIVE_QUORUM) {
            log.info("[WATCHDOG] NETWORK RECOVERED. Soft Quorum restored. Exiting Lockdown Mode.");
            activeShards.clear(); // Reseta para evitar bounces
            isLockedDown = false;
            return;
        }

        int observedNodesCount = liveNodesCount + deadNodesCount;
        if (!isLockedDown && liveNodesCount < REQUIRED_LIVE_QUORUM && observedNodesCount >= REQUIRED_LIVE_QUORUM
                && deadNodesCount >= REQUIRED_LIVE_QUORUM) {
            log.error("[CRITICAL] ⚠️ Quorum Loss Detected (live={}, dead={}). Entering SOFT QUORUM LOCKDOWN.",
                    liveNodesCount, deadNodesCount);
            enterSoftQuorumLockdown();
        }
    }

    private void maybeTriggerInfrastructureRecovery(String nodeId, long now) {
        Long lastAttemptAt = lastRecoveryAttempts.get(nodeId);
        if (lastAttemptAt != null && now - lastAttemptAt < RECOVERY_ATTEMPT_INTERVAL_MS) {
            return;
        }

        lastRecoveryAttempts.put(nodeId, now);
        log.warn("[WATCHDOG] Shard {} missed heartbeat window. Triggering recovery...", nodeId);
        triggerInfrastructureRecovery(nodeId);
    }

    /**
     * Simulates an API call to AWS/GCP or Kubernetes to restart a failed Shard.
     * In a real sovereign infra, this would be a signed request to the Infrastructure Orchestrator.
     */
    private void triggerInfrastructureRecovery(String nodeId) {
        log.info("[INFRA] 🚀 Resurrection Script triggered for node: {}. Checking instance healthy via Cloud API...", nodeId);
        // Simulation: Send a POST to any recovery endpoint if configured
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
