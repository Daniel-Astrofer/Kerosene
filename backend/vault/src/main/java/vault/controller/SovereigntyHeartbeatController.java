package vault.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vault.service.WatchdogService;
import vault.security.ShardIdentityService;

@RestController
@RequestMapping("/v1/vault")
public class SovereigntyHeartbeatController {

    private static final Logger log = LoggerFactory.getLogger(SovereigntyHeartbeatController.class);

    @Autowired
    private ShardIdentityService shardIdentityService;

    @Autowired
    private WatchdogService watchdogService;

    private static final long MAX_CLOCK_SKEW_MS = 30000; // 30 seconds

    /**
     * Endpoint for Shards to PUSH their heartbeat beacon over Tor mTLS.
     * Verified with Ed25519 signatures from the Shards' sovereign identity.
     * 
     * @param nodeId    extracted from Certificate or header
     * @param timestamp epoch ms
     * @param signature Ed25519 signature of "heartbeat:<timestamp>"
     */
    @PostMapping("/heartbeat")
    public ResponseEntity<String> receiveHeartbeat(
            @RequestHeader("X-Node-Id") String nodeId,
            @RequestHeader("X-Shard-Timestamp") long timestamp,
            @RequestHeader("X-Shard-Signature") String signature) {

        if (nodeId == null || nodeId.isBlank()) {
            return ResponseEntity.badRequest().body("Missing X-Node-Id header");
        }

        // 1. Clock skew / Anti-replay protection
        long now = System.currentTimeMillis();
        if (Math.abs(now - timestamp) > MAX_CLOCK_SKEW_MS) {
            log.warn("[Heartbeat] Rejected {} due to clock skew. Delta: {}ms", nodeId, now - timestamp);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Clock skew exceeded");
        }

        // 2. Signature Verification
        String message = "heartbeat:" + timestamp;
        if (!shardIdentityService.verifySignature(nodeId, message, signature)) {
            log.error("[SECURITY ALERT] Invalid heartbeat signature from node {}", nodeId);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid signature");
        }

        watchdogService.registerHeartbeat(nodeId);
        return ResponseEntity.ok("ACK");
    }
}
