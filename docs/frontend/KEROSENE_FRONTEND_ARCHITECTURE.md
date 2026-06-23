# Kerosene Frontend Architecture Contract

Este contrato define a organização oficial do frontend Kerosene no modelo KFE-only. Ele deve ser lido antes de qualquer movimentação de arquivos, renomeação financeira, criação de rotas ou refatoração de providers/controllers.

## Estrutura oficial

```text
frontend/lib
  app/
    bootstrap/
    routing/
    mobile/
    web_admin/

  core/
    config/
    errors/
    logging/
    network/
    security/
    storage/
    utils/

  design_system/
    tokens/
    components/
    motion/
    icons/
    brand/

  shared/
    domain/
    presentation/

  features/
    auth/
    home/
    security/
    settings/
    notifications/
    financial_accounts/
    financial_activity/
    send/
    receive/
    admin/
```

## Responsabilidades por camada

### app

`app` contém composição do produto: bootstrap, roteamento, shells mobile/web admin e providers de montagem que conectam infraestrutura com features.

Pode importar `core`, `design_system`, `shared` e `features`.

Exemplos adequados:

- `app/bootstrap/mobile_bootstrap.dart`
- `app/bootstrap/admin_bootstrap.dart`
- `app/routing/mobile_routes.dart`
- `app/routing/admin_routes.dart`
- providers de composição, como API client autenticado usado por features

### core

`core` contém infraestrutura técnica reutilizável e sem conhecimento de produto específico.

Pode conter:

- configuração
- erros/failures genéricos
- logging
- network client base
- segurança genérica
- storage genérico
- utilitários puros

Não pode importar `features`.

`core` não deve conter widgets visuais de produto, telas, rotas financeiras, casos de uso de domínio ou dependência de uma feature específica.

### design_system

`design_system` é a fonte oficial de tokens e componentes visuais.

Pode conter:

- cores, tipografia, espaçamentos e raios
- componentes visuais básicos
- motion tokens
- wrappers oficiais de ícones e animações
- tokens de marca

Não pode importar `features`.

Novos imports de UI devem preferir:

```dart
import 'package:kerosene/design_system/kerosene_design_system.dart';
```

### shared

`shared` contém elementos reutilizáveis de produto que não pertencem a uma única feature, mas já conhecem conceitos de domínio/presentação do Kerosene.

Pode conter:

- entidades compartilhadas entre features
- widgets de produto reutilizáveis
- formatadores de domínio compartilhado
- estados/presenters reutilizáveis sem acesso direto a data sources

Não deve virar uma pasta de despejo. Se algo só é usado por uma feature, deve ficar dentro da feature.

### features

`features` contém fluxos verticais do produto.

Cada feature deve seguir, quando aplicável:

```text
feature/
  data/
    datasources/
    repositories/
  domain/
    entities/
    repositories/
  application/
    usecases/
    providers/
  presentation/
    screens/
    widgets/
    controllers/
    state/
```

`presentation` não deve importar `data` diretamente. A comunicação deve passar por `application`, `domain` ou providers expostos pela própria feature.

## Regras de imports

1. `core` não importa `features`.
2. `design_system` não importa `features`.
3. `presentation` não importa `data` diretamente.
4. `features/*/data` pode importar `domain` da própria feature e infraestrutura genérica de `core`.
5. `features/*/application` orquestra use cases, providers e acesso a repositórios de domínio.
6. `features/*/presentation` depende de `application`, `domain`, `shared`, `core` genérico e `design_system`.
7. Imports relativos longos entre features devem ser evitados. Preferir package imports quando cruzar fronteiras claras.
8. Código novo de UI deve usar tokens/wrappers do design system, não literais diretos de cor, fontes, ícones ou animações.

## Nomenclatura KFE-only

O frontend ativo deve refletir o domínio KFE, não nomes financeiros legados.

Nomes permitidos para áreas financeiras ativas:

- `financial_accounts`
- `financial_activity`
- `send`
- `receive`

Nomes legados como `bitcoin_accounts`, `transactions`, `payments` e `wallet` só podem permanecer temporariamente como camada de compatibilidade, alias ou redirect documentado durante migração.

Novos arquivos, rotas, providers e textos técnicos não devem introduzir nomenclatura financeira legada.

## Política para legacy e roadmap

`_legacy` e `_roadmap` não podem existir dentro de `frontend/lib/features`.

Conteúdo legado deve ser movido para uma destas áreas:

```text
frontend/archive/legacy
docs/archive/frontend/legacy
```

Roadmap deve viver fora do código ativo:

```text
docs/roadmap/frontend
```

Código arquivado não pode ser importado por `frontend/lib` ou `frontend/test`.

## Política para arquivos grandes

Arquivos grandes devem ser quebrados antes de grandes movimentações ou renomeações.

Limite padrão:

- até 700 linhas: permitido
- 701 a 1.000 linhas: exige justificativa local clara
- acima de 1.000 linhas: deve ser tratado como monólito a quebrar antes de mover

Justificativas aceitas devem aparecer próximas ao topo do arquivo com um comentário contendo `architecture-allow-large-file` e o motivo.

Exemplo:

```dart
// architecture-allow-large-file: migração em andamento; dividir na Fase 7.2.
```

A prioridade de quebra é:

1. `bitcoin_accounts_screen.dart`
2. `send_money_screen.dart`
3. `signup_flow_screen.dart`
4. `deposits_screen.dart`
5. `sovereignty_status_screen.dart`
6. `settings_screen.dart`
7. `home_screen.dart` e seus part files

## Política para rotas legadas

Rotas antigas não devem ser removidas sem uma janela temporária de redirect/depreciação.

Mapeamento inicial:

```text
/card -> /accounts
/bitcoin/advanced -> /accounts/advanced
/history -> /activity
```

Regra:

1. Criar rota nova.
2. Manter rota antiga como redirect temporário.
3. Atualizar navegação interna para a rota nova.
4. Documentar breaking change.
5. Remover redirect apenas em fase dedicada.

Toda rota financeira legada mantida deve ter comentário explícito de redirect/depreciação contendo `legacy-route-redirect`.

## Política para providers, controllers e use cases

Providers e controllers de apresentação não devem acessar data sources ou repositories concretos diretamente.

Fluxo esperado:

```text
presentation -> application -> domain -> data
```

Regras:

- `presentation/providers` deve ser usado apenas para estado de UI ou ligação com providers de application.
- `presentation/controllers` não deve construir data sources.
- `application/providers` expõe use cases e repositórios de domínio.
- `application/usecases` concentra regras de fluxo da feature.
- `data/repositories` implementa contratos de `domain/repositories`.
- `data/datasources` encapsula HTTP, storage e APIs externas.

Exceções devem ser raras, temporárias e documentadas no próprio arquivo com `architecture-exception`.

## Validação mínima

Antes de commit em qualquer fase de refatoração frontend:

```bash
cd frontend
flutter analyze
tool/check_frontend_cleanup_rules.sh
dart run tool/check_frontend_architecture_rules.dart
git diff --check
```

Quando houver teste focado, ele deve ser executado junto da fase.
