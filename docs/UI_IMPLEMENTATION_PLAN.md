# Plano de Implementacao da UI da Kerosene

Este plano transforma a bibliografia de UX/produto em um roteiro executavel para
o frontend Flutter da Kerosene. Ele considera o codigo atual do repo, nao
screenshots antigas.

## Norte de Produto

A UI da Kerosene deve se comportar como uma interface financeira de alta
confianca:

- clareza antes de efeito visual;
- seguranca visivel em todos os momentos sensiveis;
- dinheiro, rede, taxa e destino sempre explicitos antes da confirmacao;
- erros tratados como responsabilidade do sistema, nao do usuario;
- feedback imediato para toda acao;
- sem dark patterns, urgencia artificial ou custo escondido.

## Principios Aplicados Dos Livros

1. Don Norman: affordances, signifiers, mapeamento natural, feedback e
   restricoes contra erro.
2. Steve Krug: cada tela deve ser escaneavel e obvia sem leitura longa.
3. Joel Marsh: UX como processo pratico de pesquisa, wireframe, medicao e
   iteracao.
4. Scott Hurff: toda tela precisa de estados completos, incluindo carregamento,
   vazio, erro, sucesso e estado parcial.
5. Marty Cagan: UI faz parte do discovery continuo, validando valor, usabilidade,
   viabilidade tecnica e negocio.
6. Designing Interfaces: componentes, navegacao, formularios, comandos e dados
   complexos devem seguir padroes consistentes.
7. Change by Design: equilibrar necessidade humana, viabilidade tecnica e
   estrategia de produto.
8. Evil by Design: usar como checklist anti-manipulacao, principalmente em
   dinheiro, seguranca e mineracao.
9. UX Research: toda decisao relevante deve ter pergunta, metodo, observacao,
   analise e criterio de decisao.
10. The Mom Test: validar comportamento real, nao opiniao generica sobre telas.

## Diagnostico Do Codigo Atual

- O frontend tem dois runtimes: app mobile e web admin.
- O design system existe, mas alguns tokens ainda quebravam a grid de 8pt.
- A navegacao primaria misturava `Icons.*`, cores hardcoded e labels ja
  localizados.
- `StateFeedbackView` ja existe e deve virar padrao para estados universais.
- Storybook existe, mas precisa cobrir estados de fluxo e nao apenas widgets
  atomicos.
- Telas como Home, Historico, Settings e Sovereignty ainda concentram muita UI,
  estado e regras em arquivos grandes.
- O onboarding ainda usa assets de apresentacao, enquanto a diretriz interna
  pede ilustracoes nativas ou uma excecao documentada.
- O web admin trata estados de erro/loading de forma fragmentada.

## Fase 1 - Fundacao Visual E Contratos

Objetivo: alinhar a base antes de redesenhar telas.

Entregaveis:

- normalizar `AppSpacing` para valores previsiveis de grid 8pt;
- remover hardcodes da navegacao primaria;
- trocar `Icons.*` da navegacao primaria por Lucide;
- adicionar Storybook para `StateFeedbackView`;
- definir checklist de aceite para novas telas.

Criterios de aceite:

- `flutter analyze` sem novas falhas nos arquivos alterados;
- navegacao primaria compila, esta localizada e usa tokens do design system;
- Storybook permite testar loading, empty, error e offline.

## Fase 2 - Estados Universais

Objetivo: padronizar loading, erro, vazio e estado parcial.

Entregaveis:

- evoluir `StateFeedbackView` para `KeroseneStateSurface`;
- criar `AsyncSection<T>` para `AsyncValue`;
- substituir spinners soltos por skeletons ou state surfaces;
- criar variantes admin/mobile;
- mapear erro tecnico para mensagem segura e acionavel.

Criterios de aceite:

- nenhuma tela critica fica branca, muda abruptamente ou exibe erro bruto;
- todo erro tem CTA quando retry e possivel;
- todo empty state explica o proximo passo.

## Fase 3 - Navegacao E Arquitetura De Tela

Objetivo: reduzir carga cognitiva e melhorar manutencao.

Entregaveis:

- criar `KerosenePageScaffold`;
- extrair secoes de `HomeScreen`, `DepositsScreen`, `SettingsScreen` e
  `SovereigntyStatusScreen`;
- manter telas orquestradoras pequenas;
- padronizar bottom navigation, headers, action bars e modais;
- registrar cada fluxo no Storybook.

Criterios de aceite:

- telas principais sem arquivos monoliticos;
- todo destino primario tem label, icone, tooltip e semantica;
- scroll, safe area e bottom clearance sao previsiveis.

## Fase 4 - Fluxos Financeiros

Objetivo: deixar dinheiro, rede, taxa, destino e risco sempre verificaveis.

Entregaveis:

- revisar enviar BTC;
- revisar receber por link, Lightning e onchain;
- revisar saque e confirmacao;
- revisar historico e detalhe de transacao;
- padronizar recibos e sheets de confirmacao;
- introduzir componentes `FinancialAmountBlock`, `NetworkFeePanel`,
  `TransactionReviewPanel` e `SecurityRequirementPanel`.

Criterios de aceite:

- acao final usa verbo especifico, nao CTA generico;
- taxa, rede e destino aparecem antes da confirmacao;
- dados copiados/colados recebem feedback claro;
- campos invalidos apontam causa e solucao.

## Fase 5 - Onboarding, Login E Recuperacao

Objetivo: reduzir friccao sem esconder risco.

Entregaveis:

- separar claramente criar conta, entrar e recuperar acesso;
- transformar requisitos em checklist curto;
- remover ou documentar excecao para assets visuais;
- alinhar passkey, TOTP, PIN e seed com estados consistentes;
- remover divergencias legadas de ativacao quando o backend nao exigir mais.

Criterios de aceite:

- usuario entende o que precisa antes de iniciar;
- recuperacao nao parece um fluxo secundario escondido;
- nenhum estado legado promete deposito de ativacao se backend nao usa isso.

## Fase 6 - Web Admin Operacional

Objetivo: tornar o admin uma superficie densa e auditavel.

Entregaveis:

- padronizar dashboards, tabelas, filtros e erros;
- usar skeletons admin;
- melhorar hierarquia de severidade;
- tornar status, release, auditoria e reconciliacao escaneaveis;
- avaliar realtime/polling explicitamente por modulo.

Criterios de aceite:

- operador identifica incidente em segundos;
- erro bruto nao aparece em card final;
- tabelas tem filtros, empty state e retry.

## Fase 7 - Pesquisa E Medicao Continua

Objetivo: decidir por evidencia.

Perguntas de pesquisa:

- Quando voce enviou Bitcoin pela ultima vez?
- O que voce conferiu antes de confirmar?
- Onde voce ja errou em wallet ou exchange?
- Qual informacao te faria cancelar uma transferencia?
- O que voce espera ver quando a rede Tor esta lenta?

Metricas:

- tempo ate criar conta;
- tempo ate primeiro envio;
- erros por campo;
- cancelamentos na confirmacao;
- retries por rede/API;
- telas com overflow;
- eventos de sessao expirada;
- falhas por websocket/polling.

## Checklist Para Qualquer Tela Nova

- Usa tokens do design system.
- Tem loading, empty, error, offline e success.
- Tem semantica acessivel.
- Tem Storybook.
- Nao exibe erro bruto de API.
- Nao esconde taxa, rede, destino ou risco.
- Nao usa dark pattern.
- Funciona em PT, EN e ES com texto longo.
- Passa em tela pequena e larga.
- `flutter analyze` e testes focados passam.
