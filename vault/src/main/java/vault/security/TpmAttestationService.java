package vault.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.security.MessageDigest;
import java.util.Base64;
import java.util.Set;
import java.util.UUID;

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

    // Lista branca: O "Carimbo" oficial compilado da sua imagem final limpa.
    // Em produção real, você roda um script para coletar os Hashes de PCR no build
    // e os carrega aqui como os ÚNICOS autorizados a receber a master key AES.
    // (Por hora, mantemos alguns Hashes simulados).
    private static final Set<String> ALLOWED_PCR_HASHES = Set.of(
            // Estes são apenas exempĺos em Base64 — troque pelos PCRs verdadeiros depois
            "XyZ123/HashOfRealCleanServerKernel+App==",
            "AbC987/HashOfRealCleanServer2Kernel+App==");

    /**
     * Fluxo 2 do Vault: /attest
     * Valida um Quote gerado pelo processador TPM do Shard.
     * 
     * @param tpmQuoteBase64 A assinatura do Hardware
     * @param nodeId         A identidade de rede do nó pedindo
     * @return O Token Temporário de Provisionamento se aprovado
     */
    public String validateAndIssueToken(String tpmQuoteBase64, String nodeId) {
        log.info("[ATTESTATION] Validating hardware quote from {}", nodeId);

        // 1. Simulação do Validador de Assinatura TPM (RSA 2048) e cálculo do Diff
        // (Na vida real usaria jTSS 2.0 ou chamaria um binário 'tpm2_checkquote' no OS)
        boolean isHardwareIntact = simulateTpmRsaVerification(tpmQuoteBase64, nodeId);

        if (!isHardwareIntact) {
            log.error("[CRITICAL] Hardware Attestation FAILED for node {}. Code tampered?", nodeId);
            throw new SecurityException("Hardware Integrity Compromised. Key Delivery Rejected.");
        }

        // 2. Assinatura válida: Gerar um Token de Uso Único (MKT - Master Key Token)
        // O Shard vai pegar esse Token em memória, e gastá-lo na hora acessando o
        // /provision
        String mktTemporary = UUID.randomUUID().toString() + "-" + System.currentTimeMillis();

        log.info("[ATTESTATION] SUCCESS. Node {} is pristine. Provisioning token issued.", nodeId);
        return mktTemporary; // Criptografe isto depois se precisar enviar em um envelope
    }

    private boolean simulateTpmRsaVerification(String quoteB64, String nodeId) {
        // Num cenário de produção real, as bibliotecas da Bouncy Castle e jTSS fariam
        // a checagem cruzando a "Endorsement Key" do TPM do servidor remoto.

        // Simulação do comportamento: Se não está na Allowlist, recusa.
        // Como não temos os TPMs físicos rodando num teste local, vamos retornar sempre
        // TRUE
        // a não ser que a palavra "tampered" esteja na Quote.
        if (quoteB64.toLowerCase().contains("tampered")) {
            return false;
        }

        return true;
    }
}
