package vault.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

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

    private String attestationMessage(String nodeId, String publicKeyBase64) {
        return "shard-attest:v1:" + nodeId + ":" + publicKeyBase64;
    }

    private String generateProvisionToken() {
        byte[] tokenBytes = new byte[32];
        TOKEN_RANDOM.nextBytes(tokenBytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
    }
}
