# Kerosene Design System — Frontend

Este é o contrato de implementação para trabalho de UI Flutter em `frontend/lib`.
Siga-o ao criar, refatorar ou revisar telas do aplicativo mobile, admin web e
storybook.

## Princípios

Kerosene é um aplicativo financeiro. A interface deve transmitir precisão,
legibilidade, segurança e calma operacional.

- Prefira clareza em vez de decoração.
- Use o tema, a tipografia, o espaçamento, a motion e os helpers de componentes existentes.
- Mantenha os estados de interação completos: loading, vazio, erro, desabilitado, sucesso
  e pendente devem ser explícitos.
- Use layouts densos para telas operacionais/de admin e layouts mais focados para
  fluxos de carteira mobile.
- Evite paletas avulsas, famílias de fonte ad hoc, letter spacing negativo e
  estilos inline copiados.

## Fonte da Verdade

| Item | Fonte |
| --- | --- |
| Tema mobile | `frontend/lib/core/theme/app_theme.dart` |
| Tipografia mobile | `frontend/lib/core/theme/app_typography.dart` |
| Tokens de cor mobile | `frontend/lib/core/theme/app_colors.dart` |
| Espaçamento mobile | `frontend/lib/core/theme/app_spacing.dart` |
| Helpers de componentes monocromáticos | `frontend/lib/core/theme/monochrome_theme.dart` |
| Helpers de motion | `frontend/lib/core/motion/app_motion.dart` e `frontend/lib/design_system/motion/kerosene_motion.dart` |
| Limites responsivos | `frontend/lib/core/responsive/kerosene_responsive.dart` |
| Tema admin | `frontend/lib/features/web_admin/theme/admin_theme.dart` |
| Cores admin | `frontend/lib/features/web_admin/theme/admin_colors.dart` |
| Tipografia admin | `frontend/lib/features/web_admin/theme/admin_typography.dart` |
| Localização | `frontend/lib/core/l10n/*.arb` e localizações geradas |
| Tela de referência | `frontend/lib/core/theme/design_system_template.dart` |
| Previews do Storybook | `frontend/lib/storybook` |

## Tipografia

Apenas as famílias estabelecidas são permitidas:

| Família | Uso |
| --- | --- |
| `Inter` | Corpo de texto mobile, campos de formulário, rótulos, legendas, botões. |
| `IBMPlexSansHebrew` | Números, saldos, hashes, txids, títulos densos, corpo de texto/dados admin. |
| `IBMPlexSerif` | Títulos editoriais/de exibição principais e títulos admin. |

Use `AppTypography`, `Theme.of(context).textTheme`, `AdminTypography` ou os
estilos de texto fornecidos pelo tema. Não introduza novas Google Fonts ou famílias
genéricas como `monospace` para UI de produção.

Regras:

- Letter spacing é `0` a menos que um token existente intencionalmente defina um valor
  positivo para rótulos ou botões.
- Use `AppTypography.technicalMono` ou `AppTypography.numericFontFamily` para
  saldos, PINs, endereços, txids, hashes, faturas e identificadores de protocolo.
- Use `headlineLarge`/`AppTypography.h1` apenas para o título principal de uma tela
  ou etapa de fluxo importante.
- Deixe o texto quebrar antes de reduzi-lo. Não dimensione o tipo diretamente com a largura
  da viewport.

## Tema Mobile

O mobile usa `AppTheme.themeFor(AppThemeVariant)` e suporta estas variantes:

- `dark`
- `amoled`
- `dimmed`
- `light`

Use `Theme.of(context).colorScheme` para superfícies primárias e cores de texto. Use
`AppTheme.paletteFor(appearance.themeVariant)` quando uma tela precisar de gradiente
de fundo ou valores específicos de paleta.

Tokens mobile principais:

- Destaque primário: `AppColors.primary` (`#F2A900`, ouro Bitcoin).
- Destaque secundário: `AppColors.secondary` (`#4B8BFF`).
- Sucesso/aviso/erro: `AppColors.success`, `AppColors.warning`,
  `AppColors.error`.
- Espaçamento: `AppSpacing` no grid de 8 pontos.
- Raio: `AppRadius.small`, `AppRadius.medium`, `AppRadius.large`.
- Sombras: `AppShadows.soft` e `AppShadows.neonGlow`, usadas com moderação.

`AppColors` inclui apelidos legados para compatibilidade. Novas UIs devem preferir
cores de tema semânticas e tokens atuais em vez de criar constantes adicionais.

## Superfícies Monocromáticas

`monochrome_theme.dart` fornece primitivas mais nítidas e de cantos retos usadas em
fluxos de segurança e foco.

Use:

- `monochromePanelDecoration`
- `monochromeInputDecoration`
- `monochromeFilledButtonStyle`
- `monochromeOutlinedButtonStyle`
- `monochromeTextButtonStyle`

Não misture primitivas monocromáticas com estilos de gradiente/card não relacionados dentro do
mesmo componente local, a menos que a tela ao redor já o faça.

## Tema Admin

O admin web usa seu próprio sistema visual:

- `AdminTheme.themeData`
- `AdminColors`
- `AdminTypography`

A UI admin é quadrada, monocromática, compacta e densa em dados. Prefira tabelas, cards
compactos, alinhamento forte, rótulos claros e cores de status de baixa saturação. Os tokens
de espaçamento admin ficam em `AdminTheme` (`spacingXs` até `spacing3xl`), e o
raio deve permanecer pequeno (`0`, `2`, `4` ou `6`).

Use tokens admin em `features/web_admin/**`. Não use `AppColors` mobile ou
estilo de card mobile em telas admin, a menos que um widget compartilhado exija
explicitamente.

## Layout

Regras gerais de layout:

- Use `Scaffold` e cores de fundo do tema.
- Mantenha seções de página como faixas de largura total ou layouts restritos. Evite cards
  aninhados.
- Use cards para itens repetidos, diálogos, ferramentas emolduradas e módulos de dashboard.
- Prefira `SafeArea`, `LayoutBuilder`, `ConstrainedBox`, tracks de grid estáveis e
  restrições explícitas de mínimo/máximo para comportamento responsivo.
- Evite sobreposição e corte em telas pequenas. Barras de ferramentas e linhas de ícones devem
  quebrar ou rolar intencionalmente.
- Mantenha alvos de toque grandes o suficiente para mobile e alvos de ponteiro compactos, mas claros
  para admin.
- Use widgets compartilhados existentes antes de adicionar novas primitivas de UI.

Superfícies compartilhadas comuns:

- `KeroseneResponsiveBoundary`
- `KerosenePerformanceBoundary`
- `AppPrimaryNavigation`
- `AppScreenFeedbackHost`
- `StateFeedbackView`
- `AppNotice`
- `CyberButton`
- `AnimatedLoadingButton`
- `TransactionAuthGate`
- `PinDialog`
- `BitcoinAddressBlocks`
- `KeroseneLogoLoadingView`

## Motion

Motion deve comunicar estado, hierarquia ou continuidade. Mantenha-a contida em
fluxos financeiros e admin.

Use:

- `AppMotion` para constantes/padrões de motion do aplicativo.
- `KeroseneMotion` para helpers de motion do design system.
- Transições de página existentes de `core/navigation/app_page_transitions.dart`.

Evite floreios genéricos de animação que não esclarecem o fluxo de trabalho. Operações
de rede de longa duração devem usar estados de loading estáveis e evitar mudanças de layout.

## Localização

Toda string visível ao usuário deve ser localizada, a menos que seja dado dinâmico de protocolo
ou um valor gerado.

Arquivos:

- `frontend/lib/core/l10n/app_en.arb`
- `frontend/lib/core/l10n/app_pt.arb`
- `frontend/lib/core/l10n/app_es.arb`
- Gerados `app_localizations*.dart`
- `frontend/l10n.yaml`

Uso:

1. Adicione a chave a todos os três arquivos ARB.
2. Regere as localizações quando necessário com o Flutter gen-l10n tooling.
3. Acesse strings através de `context.tr.<chave>`.

Literais inline são aceitáveis para valores dinâmicos como quantias em BTC, endereços,
txids, faturas, hashes e rótulos gerados que não são texto voltado ao usuário.

## Formulários e Ações

Use os temas de input e botão do tema ativo por padrão.

Regras:

- Prefira `FilledButton`, `OutlinedButton`, `TextButton`, botões de aplicativo existentes,
  ou botões com tema admin em vez de containers customizados com handlers de gesto.
- Estados desabilitados devem ser visualmente distintos e semanticamente desabilitados.
- Ações destrutivas exigem rotulagem clara e um padrão de confirmação quando
  podem alterar o estado de conta/segurança.
- Ações de transação devem exibir os estados de autenticação elevada, pendente, sucesso e falha
  sem perder o contexto inserido pelo usuário.
- Texto de erro deve usar mensagens traduzidas e seguras para o usuário. Payloads técnicos,
  nomes de rota, stack traces e erros brutos do Dio não devem ser exibidos diretamente.

## Dados Financeiros

UI financeira tem requisitos de formatação mais rigorosos:

- Use valores inteiros em satoshi para aritmética interna quando disponível.
- Use helpers existentes de dinheiro/transação como `MoneyDisplay`,
  `currency_logic` e utilitários de exibição de transação.
- Use tipografia técnica para quantias, endereços, faturas, txids, hashes e
  identificadores de carteira.
- Evite truncar dados críticos de pagamento sem um recurso de cópia ou visualização detalhada.
- Exiba estados pendente, confirmando, liquidado, falhou, expirou e indisponível
  explicitamente.

## Ícones e Mídia

Use primeiro o vocabulário existente de ícones e widgets do projeto. Botões apenas com ícone
precisam de tooltips a menos que o ícone seja universalmente óbvio no contexto.

Imagens devem ser usadas apenas quando esclarecem contexto de produto, lugar, pessoa, objeto ou
download. Evite imagens decorativas genéricas em fluxos operacionais.

## Acessibilidade

Expectativas mínimas:

- Respeite a configuração de escala de fonte do aplicativo através de `KeroseneResponsiveBoundary`.
- Preserve contraste suficiente contra as superfícies do tema ativo.
- Forneça rótulos/tooltips para controles não textuais.
- Mantenha a ordem de foco natural em telas web/admin.
- Evite mudanças de layout que movam ações primárias enquanto uma requisição está em andamento.

## Checklist de Criação de Tela

Antes de abrir um PR ou entregar trabalho de UI:

- A tela usa a família de tema correta: tokens do aplicativo mobile ou tokens admin.
- Strings visíveis ao usuário estão localizadas através de `context.tr`.
- Estados de loading, vazio, erro, desabilitado, pendente e sucesso são tratados.
- O comportamento responsivo foi verificado para largura mobile e largura desktop/admin.
- A tipografia usa `AppTypography`, estilos de texto do tema ou `AdminTypography`.
- O espaçamento usa `AppSpacing` ou tokens de espaçamento de `AdminTheme`.
- Dados financeiros/de protocolo usam tipografia técnica e fluxos seguros de quebra/cópia.
- Nenhuma nova paleta, fonte, componente global ou sistema de animação foi introduzido
  sem um motivo claro.
- Cobertura de Storybook ou testes de widget direcionados são adicionados para UI reutilizável complexa.
