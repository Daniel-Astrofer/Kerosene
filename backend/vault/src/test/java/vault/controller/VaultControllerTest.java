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
}
