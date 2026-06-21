package vault.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.MessageDigest;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * ─── TPM ATTESTATION SERVICE (Atestação Remota) ──────────────────────────────
 *
 * Avalia a prova de integridade (PCR Quote) entregue pelo Shard.
 * O Shard que precisa do AES Master Key só recebe ela se o hardware estiver
 * intacto,
 * provando que o kernel, o bootloader e o pacote Java .jar dele são originais.
 */
@Service
public class TpmAttestationService {

    private static final Logger log = LoggerFactory.getLogger(TpmAttestationService.class);
    private static final SecureRandom TOKEN_RANDOM = new SecureRandom();

    @Value("${vault.cluster.attestation-secret:}")
    private String clusterAttestationSecret;

    private byte[] clusterAttestationSecretBytes;
    private final Map<String, PendingChallenge> pendingChallenges = new ConcurrentHashMap<>();

    @PostConstruct
    void loadClusterAttestationSecret() {
        if (clusterAttestationSecret == null || clusterAttestationSecret.isBlank()) {
            throw new IllegalStateException("vault.cluster.attestation-secret is required.");
        }
        clusterAttestationSecretBytes = Base64.getDecoder().decode(clusterAttestationSecret);
        if (clusterAttestationSecretBytes.length < 32) {
            throw new IllegalStateException("vault.cluster.attestation-secret must decode to at least 32 bytes.");
        }
    }

    /**
     * Fluxo 2 do Vault: /attest
     * Valida um Quote gerado pelo processador TPM do Shard.
     * 
     * @param tpmQuoteBase64 A assinatura do Hardware
     * @param nodeId         A identidade de rede do nó pedindo
     * @return O Token Temporário de Provisionamento se aprovado
     */
    public String validateAndIssueToken(String tpmQuoteBase64, String nodeId, String publicKeyBase64) {
        log.info("[ATTESTATION] Validating hardware quote from {}", nodeId);

        boolean isHardwareIntact = verifyContainerAttestation(tpmQuoteBase64, nodeId, publicKeyBase64);

        if (!isHardwareIntact) {
            log.error("[CRITICAL] Hardware Attestation FAILED for node {}. Code tampered?", nodeId);
            throw new SecurityException("Hardware Integrity Compromised. Key Delivery Rejected.");
        }

        // 2. Assinatura válida: Gerar um Token de Uso Único (MKT - Master Key Token)
        // O Shard vai pegar esse Token em memória, e gastá-lo na hora acessando o
        // /provision
        String mktTemporary = generateProvisionToken();

        log.info("[ATTESTATION] SUCCESS. Node {} is pristine. Provisioning token issued.", nodeId);
        return mktTemporary; // Criptografe isto depois se precisar enviar em um envelope
    }

    public AttestationChallenge issueChallenge(String nodeId) {
        if (nodeId == null || nodeId.isBlank()) {
            throw new IllegalArgumentException("node_id is required.");
        }
        String challengeId = UUID.randomUUID().toString();
        String challengeNonce = randomUrlToken(32);
        pendingChallenges.put(challengeId, new PendingChallenge(nodeId, challengeNonce));
        return new AttestationChallenge(challengeId, challengeNonce);
    }

    public String validateV2AndIssueToken(
            String challengeId,
            String challengeNonce,
            String nodeId,
            String publicKeyBase64,
            String attestationSignatureBase64) {
        log.info("[ATTESTATION] Validating v2 software identity attestation from {}", nodeId);

        if (challengeId == null || challengeId.isBlank()) {
            throw new SecurityException("Invalid or replayed attestation challenge.");
        }

        PendingChallenge challenge = pendingChallenges.remove(challengeId);
        if (challenge == null
                || nodeId == null
                || publicKeyBase64 == null
                || attestationSignatureBase64 == null
                || !nodeId.equals(challenge.nodeId())
                || !MessageDigest.isEqual(
                        challenge.nonce().getBytes(StandardCharsets.UTF_8),
                        nullToEmpty(challengeNonce).getBytes(StandardCharsets.UTF_8))) {
            throw new SecurityException("Invalid or replayed attestation challenge.");
        }

        if (!verifyV2Signature(nodeId, publicKeyBase64, challengeId, challengeNonce, attestationSignatureBase64)) {
            throw new SecurityException("Invalid attestation signature.");
        }

        String mktTemporary = generateProvisionToken();
        log.info("[ATTESTATION] SUCCESS. Node {} passed v2 software identity attestation.", nodeId);
        return mktTemporary;
    }

    private boolean verifyContainerAttestation(String quote, String nodeId, String publicKeyBase64) {
        if (quote == null || !quote.startsWith("v1:") || nodeId == null || publicKeyBase64 == null) {
            return false;
        }
        String expected = "v1:" + hmacAttestation(nodeId, publicKeyBase64);
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                quote.getBytes(StandardCharsets.UTF_8));
    }

    private String hmacAttestation(String nodeId, String publicKeyBase64) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(clusterAttestationSecretBytes, "HmacSHA256"));
            byte[] digest = mac.doFinal(attestationMessage(nodeId, publicKeyBase64)
                    .getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(digest);
        } catch (Exception exception) {
            throw new IllegalStateException("Failed to verify shard attestation.", exception);
        }
    }

    private boolean verifyV2Signature(
            String nodeId,
            String publicKeyBase64,
            String challengeId,
            String challengeNonce,
            String attestationSignatureBase64) {
        try {
            byte[] pubKeyBytes = Base64.getDecoder().decode(publicKeyBase64);
            byte[] signatureBytes = Base64.getDecoder().decode(attestationSignatureBase64);

            KeyFactory keyFactory = KeyFactory.getInstance("Ed25519");
            PublicKey publicKey = keyFactory.generatePublic(new X509EncodedKeySpec(pubKeyBytes));

            Signature signature = Signature.getInstance("Ed25519");
            signature.initVerify(publicKey);
            signature.update(attestationMessageV2(nodeId, publicKeyBase64, challengeId, challengeNonce)
                    .getBytes(StandardCharsets.UTF_8));
            return signature.verify(signatureBytes);
        } catch (Exception exception) {
            log.warn("[ATTESTATION] v2 signature verification failed for node {}: {}", nodeId, exception.getMessage());
            return false;
        }
    }

    private String attestationMessage(String nodeId, String publicKeyBase64) {
        return "shard-attest:v1:" + nodeId + ":" + publicKeyBase64;
    }

    private String attestationMessageV2(
            String nodeId,
            String publicKeyBase64,
            String challengeId,
            String challengeNonce) {
        return "vault-attest:v2\n"
                + "node_id=" + nodeId + "\n"
                + "public_key=" + publicKeyBase64 + "\n"
                + "challenge_id=" + challengeId + "\n"
                + "challenge_nonce=" + challengeNonce;
    }

    private String generateProvisionToken() {
        return randomUrlToken(32);
    }

    private String randomUrlToken(int bytes) {
        byte[] tokenBytes = new byte[32];
        if (bytes != tokenBytes.length) {
            tokenBytes = new byte[bytes];
        }
        TOKEN_RANDOM.nextBytes(tokenBytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    public record AttestationChallenge(String challengeId, String challengeNonce) {
    }

    private record PendingChallenge(String nodeId, String nonce) {
    }
}
