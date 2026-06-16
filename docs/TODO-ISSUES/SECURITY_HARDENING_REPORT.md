# Relatório de Fortalecimento de Segurança

Data: 2026-06-14

## Resumo

- Centralizou a autorização de endpoints HTTP em `EndpointPolicyRegistry`.
- Alterou o fallback do Spring Security de autenticado-por-padrão para negar-por-padrão com `.anyRequest().denyAll()`.
- Adicionou autovalidação do registry para padrões de política em branco, malformados e duplicados.
- Adicionou cobertura de regressão que varre todos os mapeamentos de `@RestController` e falha quando qualquer endpoint não possui uma política explícita no registry.
- Adicionou uma asserção de regressão de negar-por-padrão para um endpoint não declarado.
- Fechou lacunas de cobertura de política de rota para endpoints de wallet autenticados, endpoints de base-path autenticados (`/notifications`, `/auth/totp`) e o base-path de inventário de dispositivos admin (`/auth/admin/devices`).
- Classificou pontos de entrada de login/cadastro por device-key (`/auth/device-key/challenge`, `/auth/device-key/verify` e início/fim de onboarding) como públicos, mantendo o registro de device-key e o gerenciamento de inventário autenticados.

## Baldes de Política

- Público: assets estáticos de aplicação web, sondas de saúde/liveness, pontos de entrada de cadastro/login, pontos de entrada públicos de onboarding de recuperação/passkey/device-key, desafios de login e verificação públicos de device-key/passkey, links públicos de recebimento, webhooks do BTCPay, status/ping de soberania, handshake de websocket e metadados públicos de release/mobile.
- Admin: operações de admin, endpoints de gerenciamento de autenticação admin, endpoints de tesouraria, operações de auditoria sensíveis e caminhos de documentação Swagger/framework.
- Autenticado: segurança de conta, gerenciamento de TOTP, registro e gerenciamento de inventário de dispositivo/passkey, ledger, wallet, conta Bitcoin, KFE, mineração, pagamento, transação, notificação, onramp/economia, quórum, saúde detalhada e endpoints de soberania não públicos.

## Verificação de Cobertura

- Varredura estática de controllers: 40 REST controllers, 164 declarações de endpoint, 156 caminhos de controller únicos inspecionados.
- Padrões de política declarados: 98.
- Distribuição de política de caminho de controller único: 27 públicos, 26 admin, 103 autenticados.
- Políticas declaradas faltantes: 0.

## Status de Regressão

Comando executado:

```bash
./gradlew test --tests source.common.security.EndpointPolicyRegistryTest --tests source.auth.application.infra.security.SecurityCorsConfigurationTest
```

Resultado no sandbox:

- O cache padrão do wrapper falhou porque `/home/codex1/.gradle` é somente leitura.
- `GRADLE_USER_HOME=/tmp/gradle-home` gravável permitiu que o wrapper do Gradle iniciasse.
- A execução do Gradle ainda falhou antes de executar os testes porque este sandbox bloqueia o socket do servidor TCP local usado pelo daemon de uso único do Gradle (`java.net.SocketException: Operation not permitted`).
- A verificação estática neste sandbox confirmou que a validação do registry passa e todos os endpoints de controller varridos possuem políticas declaradas após adicionar `/wallet/**`, `/notifications`, `/auth/totp`, `/auth/admin/devices` e os pontos de entrada públicos de login/onboarding por device-key.

A suíte de regressão de segurança está pronta para ser executada em um ambiente normal de desenvolvedor ou CI com:

```bash
cd backend/kerosene
./gradlew test --tests source.common.security.EndpointPolicyRegistryTest --tests source.auth.application.infra.security.SecurityCorsConfigurationTest
```
