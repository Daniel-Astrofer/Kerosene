package vault.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Validates the cryptographic signatures of Shards (IS, CH, SG).
 * Ensures that heartbeats are coming from authentic, registered nodes.
 */
@Service
public class ShardIdentityService {

    private static final Logger log = LoggerFactory.getLogger(ShardIdentityService.class);

    // NodeId -> Base64 Public Key
    // In production, this would be loaded from a signed config or a database
    // populated during the initial manual attestation of the cluster.
    private final Map<String, String> registeredPublicKeys = new ConcurrentHashMap<>();

    public ShardIdentityService() {
        // For development, we might auto-register the first key we see for a node,
        // or have a list of pre-authorized node IDs.
    }

    /**
     * Registers a shard's public key.
     * In a real system, this would happen during a 'join' ceremony.
     */
    public void registerShardKey(String nodeId, String publicKeyBase64) {
        log.info("[Identity] Registering public key for node: {}", nodeId);
        registeredPublicKeys.put(nodeId, publicKeyBase64);
    }

    /**
     * Verifies a signed message from a shard.
     */
    public boolean verifySignature(String nodeId, String message, String signatureBase64) {
        String publicKeyBase64 = registeredPublicKeys.get(nodeId);
        if (publicKeyBase64 == null) {
            log.warn("[Identity] No registered key for node: {}", nodeId);
            return false;
        }

        try {
            byte[] pubKeyBytes = Base64.getDecoder().decode(publicKeyBase64);
            byte[] sigBytes = Base64.getDecoder().decode(signatureBase64);

            KeyFactory kf = KeyFactory.getInstance("Ed25519");
            PublicKey pubKey = kf.generatePublic(new X509EncodedKeySpec(pubKeyBytes));

            Signature sig = Signature.getInstance("Ed25519");
            sig.initVerify(pubKey);
            sig.update(message.getBytes(StandardCharsets.UTF_8));

            return sig.verify(sigBytes);
        } catch (Exception e) {
            log.error("[Identity] Signature verification failed for node {}: {}", nodeId, e.getMessage());
            return false;
        }
    }

    public boolean isKnownNode(String nodeId) {
        return registeredPublicKeys.containsKey(nodeId);
    }
}
