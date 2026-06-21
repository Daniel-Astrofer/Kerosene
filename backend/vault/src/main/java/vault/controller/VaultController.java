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
import org.springframework.beans.factory.annotation.Value;
import jakarta.annotation.PostConstruct;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import vault.security.ShardIdentityService;

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

    @Autowired
    private ShardIdentityService shardIdentityService;

    // Tokens de sessão efêmeros: Token -> NodeId + expiry (Em RAM, não vai pra Redis)
    private final Map<String, ProvisionToken> provisionTokens = new ConcurrentHashMap<>();

    // M-of-N Quorum State para Armar o Cofre
    private final java.util.Set<String> armApprovingDirectors = ConcurrentHashMap.newKeySet();
    private final Map<String, byte[]> directorHmacSecrets = new ConcurrentHashMap<>();
    private String pendingMasterKeyBase64 = null;

    @Value("${vault.required-approvals:2}")
    private int requiredApprovals;

    @Value("${vault.director.hmac-secrets:}")
    private String configuredDirectorSecrets;

    @Value("${vault.provision-token.ttl-ms:60000}")
    private long provisionTokenTtlMs;

    private volatile boolean isArmed = false;

    // que a chave nunca toque o ambiente do orquestrador.

    @PostConstruct
    void loadDirectorSecrets() {
        Map<String, byte[]> parsed = parseDirectorSecrets(configuredDirectorSecrets);
        if (parsed.isEmpty()) {
            throw new IllegalStateException(
                    "vault.director.hmac-secrets is required. Refusing to boot Vault with hardcoded directors.");
        }
        if (requiredApprovals < 1 || requiredApprovals > parsed.size()) {
            throw new IllegalStateException("vault.required-approvals must be between 1 and the number of directors.");
        }
        if (provisionTokenTtlMs <= 0) {
            throw new IllegalStateException("vault.provision-token.ttl-ms must be greater than zero.");
        }
        directorHmacSecrets.putAll(parsed);
        log.info("[VAULT] Loaded {} director HMAC identities. Required approvals: {}",
                directorHmacSecrets.size(), requiredApprovals);
    }

    /**
     * POST /arm
     * Exclusivo para Diretores injetarem os Fragmentos da Chave via Quórum M-of-N.
     * Na prática, requer TLS Cliente + Assinaturas MFA independentes.
     */
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
        if (directorId == null || !directorHmacSecrets.containsKey(directorId)) {
            log.warn("[SECURITY ALERT] Attempt to arm vault with unauthorized Director ID: {}", directorId);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Unauthorized Director ID.");
        }

        String reqMasterKeyB64 = payload.get("master_key");
        if (reqMasterKeyB64 == null) {
            return ResponseEntity.badRequest().body("Requires payload: { 'master_key': '...' }");
        }
        if (!isValidMasterKey(reqMasterKeyB64)) {
            return ResponseEntity.badRequest().body("master_key must be Base64-encoded AES-256 material.");
        }

        if (!validDirectorSignature(directorId, signature, reqMasterKeyB64)) {
            log.warn("[SECURITY ALERT] Invalid arm signature from Director: {}", directorId);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid cryptographic signature.");
        }

        log.info("[ARM] Validated director signature for {}. Processing quorum...", directorId);

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

        if (armApprovingDirectors.size() >= requiredApprovals) {
            byte[] keyDecoded = Base64.getDecoder().decode(pendingMasterKeyBase64);

            // 3. Tranca a chave na RAM via sysCall (Kernel mlock)
            vaultMemoryLocker.writeMasterKey(keyDecoded);
            this.isArmed = true;

            // Limpa rastros temporários
            pendingMasterKeyBase64 = null;
            armApprovingDirectors.clear();

            log.info("Vault ARMED by quorum of {} directors.", requiredApprovals);
            return ResponseEntity
                    .ok("Quorum Reached (" + requiredApprovals + "). Vault is ARMED and LOCKED in physical memory.");
        }

        return ResponseEntity.status(HttpStatus.ACCEPTED)
                .body("Signature accepted. " + armApprovingDirectors.size() + "/" + requiredApprovals
                        + " approvals reached. Waiting for more directors.");
    }

    private Map<String, byte[]> parseDirectorSecrets(String configuredSecrets) {
        Map<String, byte[]> parsed = new HashMap<>();
        if (configuredSecrets == null || configuredSecrets.isBlank()) {
            return parsed;
        }
        for (String entry : configuredSecrets.split(",")) {
            String[] parts = entry.trim().split(":", 2);
            if (parts.length != 2 || parts[0].isBlank() || parts[1].isBlank()) {
                throw new IllegalStateException("Invalid director HMAC secret entry: " + entry);
            }
            byte[] secret = Base64.getDecoder().decode(parts[1].trim());
            if (secret.length < 32) {
                throw new IllegalStateException("Director HMAC secret must decode to at least 32 bytes: " + parts[0]);
            }
            parsed.put(parts[0].trim(), secret);
        }
        return parsed;
    }

    private boolean isValidMasterKey(String masterKeyBase64) {
        try {
            byte[] decoded = Base64.getDecoder().decode(masterKeyBase64);
            try {
                return decoded.length == 32;
            } finally {
                java.util.Arrays.fill(decoded, (byte) 0);
            }
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }

    private boolean validDirectorSignature(String directorId, String signature, String masterKeyBase64) {
        if (signature == null || !signature.startsWith("v1:")) {
            return false;
        }
        byte[] secret = directorHmacSecrets.get(directorId);
        if (secret == null) {
            return false;
        }
        String expected = "v1:" + hmacArmSignature(secret, directorId, masterKeyBase64);
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                signature.getBytes(StandardCharsets.UTF_8));
    }

    private String hmacArmSignature(byte[] secret, String directorId, String masterKeyBase64) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret, "HmacSHA256"));
            byte[] digest = mac.doFinal(armMessage(directorId, masterKeyBase64).getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(digest);
        } catch (Exception exception) {
            throw new IllegalStateException("Failed to compute director arm signature.", exception);
        }
    }

    private String armMessage(String directorId, String masterKeyBase64) {
        return "vault-arm:v1:" + directorId + ":" + masterKeyBase64;
    }

    /**
     * GET /challenge
     * Issues a one-time challenge for v2 software identity attestation.
     */
    @GetMapping("/challenge")
    public ResponseEntity<Map<String, String>> challenge(
            @RequestHeader(value = "X-Node-Id", required = false) String nodeId) {
        if (nodeId == null || nodeId.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Requires X-Node-Id header."));
        }

        TpmAttestationService.AttestationChallenge challenge = tpmAttestation.issueChallenge(nodeId);
        return ResponseEntity.ok(Map.of(
                "challenge_id", challenge.challengeId(),
                "challenge_nonce", challenge.challengeNonce()));
    }

    /**
     * POST /attest
     * Shard manda sua prova via mTLS provando pureza de código.
     */
    @PostMapping("/attest")
    public ResponseEntity<String> attestShard(@RequestBody Map<String, String> payload) {
        String tpmQuote = payload.get("tpm_quote");
        String nodeId = payload.get("node_id");
        String pubKey = payload.get("public_key");

        if (!isArmed) {
            log.warn("[ATTEST] Rejected: Vault is NOT ARMED. Owner must arm it first.");
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body("Vault is not armed.");
        }

        if (watchdogService.isLockedDown()) {
            log.warn("[ATTEST] Rejected: Vault is in SOFT QUORUM LOCKDOWN.");
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("Vault network is compromised (Quorum Loss).");
        }

        if (nodeId == null) {
            return ResponseEntity.badRequest().body("Requires 'node_id'");
        }

        try {
            String mkt;
            if (isV2Attestation(payload)) {
                mkt = tpmAttestation.validateV2AndIssueToken(
                        payload.get("challenge_id"),
                        payload.get("challenge_nonce"),
                        nodeId,
                        pubKey,
                        payload.get("attestation_signature"));
            } else {
                if (tpmQuote == null) {
                    return ResponseEntity.badRequest().body("Requires 'tpm_quote' and 'node_id'");
                }
                // Atesta o hardware. Se passar, recebe Token. Se falhar, SecurityException.
                mkt = tpmAttestation.validateAndIssueToken(tpmQuote, nodeId, pubKey);
            }
            purgeExpiredProvisionTokens();

            if (pubKey != null && !pubKey.isBlank()) {
                shardIdentityService.registerShardKey(nodeId, pubKey);
            }

            // Grava Token -> Nó (Só esse nó poderá usar este token)
            provisionTokens.put(mkt, new ProvisionToken(nodeId, System.currentTimeMillis() + provisionTokenTtlMs));

            // REGISTRA O SHARD NO WATCHDOG IMEDIATAMENTE (Evita falso-positivo de Missed Heartbeat logo no boot)
            watchdogService.registerHeartbeat(nodeId);

            return ResponseEntity.ok(mkt);

        } catch (SecurityException e) {
            log.error("[ATTEST] Attestation failed: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(e.getMessage());
        }
    }

    private boolean isV2Attestation(Map<String, String> payload) {
        return payload.containsKey("challenge_id")
                || payload.containsKey("challenge_nonce")
                || payload.containsKey("attestation_signature");
    }

    /**
     * GET /provision
     * Entregando a coroa. Somente se o Token bater.
     * Entrega por JSON e Shard decodifica da RAM para sua RAM.
     */
    @GetMapping("/provision")
    public ResponseEntity<Map<String, String>> provisionKey(
            @RequestHeader(value = "Authorization", required = false) String mkt,
            @RequestHeader(value = "X-Node-Id", required = false) String nodeId) {

        if (!isArmed) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("error", "Vault is not armed."));
        }

        if (watchdogService.isLockedDown()) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(Map.of("error", "Vault network is compromised (Quorum Loss)."));
        }

        String tokenStripped = bearerToken(mkt);
        if (tokenStripped == null || nodeId == null || nodeId.isBlank()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        ProvisionToken provisionToken = provisionTokens.get(tokenStripped);
        long now = System.currentTimeMillis();
        if (provisionToken != null && provisionToken.isExpired(now)) {
            provisionTokens.remove(tokenStripped);
            provisionToken = null;
        }

        if (provisionToken == null || !nodeId.equals(provisionToken.nodeId())) {
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

    private String bearerToken(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            return null;
        }
        String token = authorizationHeader.substring("Bearer ".length()).trim();
        return token.isEmpty() ? null : token;
    }

    private void purgeExpiredProvisionTokens() {
        long now = System.currentTimeMillis();
        provisionTokens.entrySet().removeIf(entry -> entry.getValue().isExpired(now));
    }

    private record ProvisionToken(String nodeId, long expiresAtMillis) {
        boolean isExpired(long nowMillis) {
            return nowMillis >= expiresAtMillis;
        }
    }
}
