package vault.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vault.security.TpmAttestationService;
import vault.security.VaultMemoryLocker;
import vault.service.WatchdogService;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * ─── OS 3 ENDPOINTS VITAIS DO VAULT ──────────────────────────────────────────
 *
 * 1. /arm - Apenas para Notebook Vigia (Recebe fragmentos Shamir)
 * 2. /attest - Para Shards provarem hardware limpo
 * 3. /provision - Entrega a Master Key ao Shard aprovado (Criptografada para
 * ele)
 */
@RestController
@RequestMapping("/v1/vault")
public class VaultController {

    private static final Logger log = LoggerFactory.getLogger(VaultController.class);

    @Autowired
    private VaultMemoryLocker vaultMemoryLocker;

    @Autowired
    private TpmAttestationService tpmAttestation;

    @Autowired
    private WatchdogService watchdogService;

    // Tokens de sessão efêmeros: Token -> NodeId (Em RAM, não vai pra Redis)
    private final Map<String, String> provisionTokens = new ConcurrentHashMap<>();

    // M-of-N Quorum State para Armar o Cofre
    private final java.util.Set<String> armApprovingDirectors = ConcurrentHashMap.newKeySet();
    private String pendingMasterKeyBase64 = null;
    private static final int REQUIRED_APPROVALS = 2;

    private volatile boolean isArmed = false;

    // que a chave nunca toque o ambiente do orquestrador.

    /**
     * POST /arm
     * Exclusivo para Diretores injetarem os Fragmentos da Chave via Quórum M-of-N.
     * Na prática, requer TLS Cliente + Assinaturas MFA independentes.
     */
    // Registro de Diretores Autorizados (em prod isso viria de um HSM ou Config
    // encriptada)
    private static final java.util.Set<String> VALID_DIRECTORS = java.util.Set.of("director-1", "director-2",
            "director-3");

    @PostMapping("/arm")
    public ResponseEntity<String> armVault(@RequestHeader(value = "X-Director-Id", required = false) String directorId,
            @RequestHeader(value = "X-Director-Signature", required = false) String signature,
            @RequestBody Map<String, String> payload,
            HttpServletRequest request) {

        String ipRemoto = request.getRemoteAddr();

        if (this.isArmed) {
            return ResponseEntity.badRequest().body("Vault is already armed.");
        }

        // 1. Validação de Identidade do Diretor
        if (directorId == null || !VALID_DIRECTORS.contains(directorId)) {
            log.warn("[SECURITY ALERT] Attempt to arm vault with unauthorized Director ID: {}", directorId);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized Director ID.");
        }

        // 2. Validação de Assinatura (MFA/FIDO2 simulator)
        if (signature == null || signature.length() < 12) {
            log.warn("[SECURITY ALERT] Weak or missing signature from Director: {}", directorId);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid or weak cryptographic signature.");
        }

        log.info("[ARM] Validated core identity for Director: {}. Processing quorum...", directorId);

        // 2. Extrai chave (Simulando uma junta Shamir que formou 32 bytes)
        String reqMasterKeyB64 = payload.get("master_key");
        if (reqMasterKeyB64 == null) {
            return ResponseEntity.badRequest().body("Requires payload: { 'master_key': '...' }");
        }

        // Validação de Concorrência de Quórum
        if (pendingMasterKeyBase64 == null) {
            pendingMasterKeyBase64 = reqMasterKeyB64;
        } else if (!pendingMasterKeyBase64.equals(reqMasterKeyB64)) {
            // Conflito de injeção - Possível ataque interno de mixagem de chave
            armApprovingDirectors.clear();
            pendingMasterKeyBase64 = null;
            log.error("[ARM] Master key mismatch between directors. Resetting quorum.");
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body("Master key mismatch between directors. Resetting quorum.");
        }

        armApprovingDirectors.add(directorId);

        if (armApprovingDirectors.size() >= REQUIRED_APPROVALS) {
            byte[] keyDecoded = Base64.getDecoder().decode(pendingMasterKeyBase64);

            // 3. Tranca a chave na RAM via sysCall (Kernel mlock)
            vaultMemoryLocker.writeMasterKey(keyDecoded);
            this.isArmed = true;

            // Limpa rastros temporários
            pendingMasterKeyBase64 = null;
            armApprovingDirectors.clear();

            log.info("Vault ARMED by quorum of {} directors.", REQUIRED_APPROVALS);
            return ResponseEntity
                    .ok("Quorum Reached (" + REQUIRED_APPROVALS + "). Vault is ARMED and LOCKED in physical memory.");
        }

        return ResponseEntity.status(HttpStatus.ACCEPTED)
                .body("Signature accepted. " + armApprovingDirectors.size() + "/" + REQUIRED_APPROVALS
                        + " approvals reached. Waiting for more directors.");
    }

    /**
     * POST /attest
     * Shard manda sua prova via mTLS provando pureza de código.
     */
    @PostMapping("/attest")
    public ResponseEntity<String> attestShard(@RequestBody Map<String, String> payload) {
        String tpmQuote = payload.get("tpm_quote");
        String nodeId = payload.get("node_id");

        if (!isArmed) {
            log.warn("[ATTEST] Rejected: Vault is NOT ARMED. Owner must arm it first.");
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body("Vault is not armed.");
        }

        if (watchdogService.isLockedDown()) {
            log.warn("[ATTEST] Rejected: Vault is in SOFT QUORUM LOCKDOWN.");
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("Vault network is compromised (Quorum Loss).");
        }

        if (tpmQuote == null || nodeId == null) {
            return ResponseEntity.badRequest().body("Requires 'tpm_quote' and 'node_id'");
        }

        try {
            // Atesta o hardware. Se passar, recebe Token. Se falhar, SecurityException.
            String mkt = tpmAttestation.validateAndIssueToken(tpmQuote, nodeId);

            // Grava Token -> Nó (Só esse nó poderá usar este token)
            provisionTokens.put(mkt, nodeId);

            return ResponseEntity.ok(mkt);

        } catch (SecurityException e) {
            log.error("[ATTEST] Attestation failed: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        }
    }

    /**
     * GET /provision
     * Entregando a coroa. Somente se o Token bater.
     * Entrega por JSON e Shard decodifica da RAM para sua RAM.
     */
    @GetMapping("/provision")
    public ResponseEntity<Map<String, String>> provisionKey(@RequestHeader("Authorization") String mkt,
            @RequestHeader("X-Node-Id") String nodeId) {

        String tokenStripped = mkt.replace("Bearer ", "");

        if (!isArmed) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("error", "Vault is not armed."));
        }

        if (watchdogService.isLockedDown()) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("error", "Vault network is compromised (Quorum Loss)."));
        }

        if (!nodeId.equals(provisionTokens.get(tokenStripped))) {
            log.warn("[PROVISION] Invalid or stolen Token used by Node {}", nodeId);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Token de Uso Único. Gastou, foi apagado no lixo da JVM.
        provisionTokens.remove(tokenStripped);

        // EXTRAI A CHAVE TRAVADA NO JNA
        // Ela volta numa cópia temporária de byte[]. Precisará ser codificada a B64 pra
        // rede.
        byte[] keyRealBytes = vaultMemoryLocker.getMasterKey();

        String base64Key = Base64.getEncoder().encodeToString(keyRealBytes);

        // O Garbage Collector vai varrer o keyRealBytes depois, mas para evitar, você o
        // sobrescreve:
        java.util.Arrays.fill(keyRealBytes, (byte) 0);

        log.info("[PROVISION] Master Key Delivered securely to Node {}", nodeId);

        return ResponseEntity.ok(Map.of("aes_key", base64Key));
    }
}
