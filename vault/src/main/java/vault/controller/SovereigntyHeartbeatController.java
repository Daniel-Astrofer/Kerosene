package vault.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import vault.service.WatchdogService;

@RestController
@RequestMapping("/v1/vault")
public class SovereigntyHeartbeatController {

    private static final Logger log = LoggerFactory.getLogger(SovereigntyHeartbeatController.class);

    @Autowired
    private WatchdogService watchdogService;

    /**
     * Endpoint for Shards to PUSH their heartbeat beacon over Tor mTLS.
     * Replaces the old Watchdog pull model that leaked DNS and geometry.
     * 
     * @param nodeId Em producao, isso viria extraido do certificado mTLS do
     *               cliente.
     */
    @PostMapping("/heartbeat")
    public ResponseEntity<String> receiveHeartbeat(@RequestHeader("X-Node-Id") String nodeId) {
        if (nodeId == null || nodeId.isBlank()) {
            return ResponseEntity.badRequest().body("Missing X-Node-Id header");
        }

        // Em producao, a autenticidade desse request e garantida pelo
        // handshake mTLS no Ingress/Tomcat.
        watchdogService.registerHeartbeat(nodeId);

        return ResponseEntity.ok("ACK");
    }
}
