package vault.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.util.ReflectionTestUtils;
import vault.security.ShardIdentityService;
import vault.security.TpmAttestationService;
import vault.security.VaultMemoryLocker;
import vault.service.WatchdogService;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.Signature;
import java.util.Base64;
import java.util.Map;

class VaultControllerTest {

    private static final byte[] ATTESTATION_SECRET = "0123456789abcdef0123456789abcdef".getBytes(StandardCharsets.UTF_8);
    private static final String NODE_ID = "node-is";
    private static final String PUBLIC_KEY = Base64.getEncoder()
            .encodeToString("test-public-key".getBytes(StandardCharsets.UTF_8));

    @Test
    void provisionRequiresBearerToken() {
        VaultMemoryLocker memoryLocker = mock(VaultMemoryLocker.class);
        VaultController controller = controller(memoryLocker, 60_000);
        String token = attest(controller);

        ResponseEntity<Map<String, String>> response = controller.provisionKey(token, NODE_ID);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        verify(memoryLocker, never()).getMasterKey();
    }

    @Test
    void provisionTokenIsSingleUse() {
        byte[] masterKey = "0123456789abcdef0123456789abcdef".getBytes(StandardCharsets.UTF_8);
        VaultMemoryLocker memoryLocker = mock(VaultMemoryLocker.class);
        when(memoryLocker.getMasterKey()).thenReturn(masterKey.clone());
        VaultController controller = controller(memoryLocker, 60_000);
        String token = attest(controller);

        ResponseEntity<Map<String, String>> firstResponse = controller.provisionKey("Bearer " + token, NODE_ID);
        ResponseEntity<Map<String, String>> secondResponse = controller.provisionKey("Bearer " + token, NODE_ID);

        assertThat(firstResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(firstResponse.getBody()).containsEntry("aes_key", Base64.getEncoder().encodeToString(masterKey));
        assertThat(secondResponse.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void provisionTokenExpiresBeforeUse() throws InterruptedException {
        VaultMemoryLocker memoryLocker = mock(VaultMemoryLocker.class);
        VaultController controller = controller(memoryLocker, 1);
        String token = attest(controller);

        Thread.sleep(10);
        ResponseEntity<Map<String, String>> response = controller.provisionKey("Bearer " + token, NODE_ID);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        verify(memoryLocker, never()).getMasterKey();
    }

    @Test
    void v2AttestationAcceptsChallengeBoundSignature() throws Exception {
        VaultController controller = controller(mock(VaultMemoryLocker.class), 60_000);
        KeyPair keyPair = keyPair();
        String publicKey = Base64.getEncoder().encodeToString(keyPair.getPublic().getEncoded());

        ResponseEntity<String> response = controller.attestShard(v2Payload(controller, keyPair, publicKey));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotBlank();
    }

    @Test
    void v2AttestationRejectsReplayedChallenge() throws Exception {
        VaultController controller = controller(mock(VaultMemoryLocker.class), 60_000);
        KeyPair keyPair = keyPair();
        String publicKey = Base64.getEncoder().encodeToString(keyPair.getPublic().getEncoded());
        Map<String, String> payload = v2Payload(controller, keyPair, publicKey);

        ResponseEntity<String> firstResponse = controller.attestShard(payload);
        ResponseEntity<String> replayResponse = controller.attestShard(payload);

        assertThat(firstResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(replayResponse.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    @Test
    void v2AttestationRejectsWrongSignature() throws Exception {
        VaultController controller = controller(mock(VaultMemoryLocker.class), 60_000);
        KeyPair signer = keyPair();
        KeyPair advertisedKey = keyPair();
        String publicKey = Base64.getEncoder().encodeToString(advertisedKey.getPublic().getEncoded());

        ResponseEntity<String> response = controller.attestShard(v2Payload(controller, signer, publicKey));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.FORBIDDEN);
    }

    private VaultController controller(VaultMemoryLocker memoryLocker, long provisionTokenTtlMs) {
        VaultController controller = new VaultController();
        WatchdogService watchdogService = mock(WatchdogService.class);
        when(watchdogService.isLockedDown()).thenReturn(false);

        ReflectionTestUtils.setField(controller, "vaultMemoryLocker", memoryLocker);
        ReflectionTestUtils.setField(controller, "tpmAttestation", tpmAttestationService());
        ReflectionTestUtils.setField(controller, "watchdogService", watchdogService);
        ReflectionTestUtils.setField(controller, "shardIdentityService", new ShardIdentityService());
        ReflectionTestUtils.setField(controller, "provisionTokenTtlMs", provisionTokenTtlMs);
        ReflectionTestUtils.setField(controller, "isArmed", true);

        return controller;
    }

    private TpmAttestationService tpmAttestationService() {
        TpmAttestationService service = new TpmAttestationService();
        ReflectionTestUtils.setField(service, "clusterAttestationSecretBytes", ATTESTATION_SECRET);
        return service;
    }

    private String attest(VaultController controller) {
        ResponseEntity<String> response = controller.attestShard(Map.of(
                "tpm_quote", quote(),
                "node_id", NODE_ID,
                "public_key", PUBLIC_KEY));

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotBlank();
        return response.getBody();
    }

    private String quote() {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(ATTESTATION_SECRET, "HmacSHA256"));
            byte[] digest = mac.doFinal(("shard-attest:v1:" + NODE_ID + ":" + PUBLIC_KEY)
                    .getBytes(StandardCharsets.UTF_8));
            return "v1:" + Base64.getEncoder().encodeToString(digest);
        } catch (Exception exception) {
            throw new IllegalStateException("Failed to sign test attestation.", exception);
        }
    }

    private Map<String, String> v2Payload(VaultController controller, KeyPair keyPair, String publicKey)
            throws Exception {
        ResponseEntity<Map<String, String>> challengeResponse = controller.challenge(NODE_ID);
        assertThat(challengeResponse.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(challengeResponse.getBody()).isNotNull();

        String challengeId = challengeResponse.getBody().get("challenge_id");
        String challengeNonce = challengeResponse.getBody().get("challenge_nonce");
        String signature = signV2(keyPair, publicKey, challengeId, challengeNonce);

        return Map.of(
                "challenge_id", challengeId,
                "challenge_nonce", challengeNonce,
                "public_key", publicKey,
                "node_id", NODE_ID,
                "attestation_signature", signature);
    }

    private KeyPair keyPair() throws Exception {
        return KeyPairGenerator.getInstance("Ed25519").generateKeyPair();
    }

    private String signV2(KeyPair keyPair, String publicKey, String challengeId, String challengeNonce)
            throws Exception {
        Signature signature = Signature.getInstance("Ed25519");
        signature.initSign(keyPair.getPrivate());
        signature.update(("vault-attest:v2\n"
                + "node_id=" + NODE_ID + "\n"
                + "public_key=" + publicKey + "\n"
                + "challenge_id=" + challengeId + "\n"
                + "challenge_nonce=" + challengeNonce).getBytes(StandardCharsets.UTF_8));
        return Base64.getEncoder().encodeToString(signature.sign());
    }
}
