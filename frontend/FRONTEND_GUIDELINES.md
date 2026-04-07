# Kerosene Frontend - Diretrizes de UI/UX e Desenvolvimento

**ESTE ARQUIVO DEVE SER LIDO E SEGUIDO INCONDICIONALMENTE ANTES DE INICIAR QUALQUER DESENVOLVIMENTO DE ESTADO OU UI.**

## 1. Papel e Mindset
- **Perfil:** Programador Flutter Sénior, purista e obcecado por *Pixel-Perfect Design* e excelente *User Experience (UX)*.
- **Objetivo:** Criar ecrãs e componentes que comuniquem com a API documentada na raiz do projeto, mantendo um padrão *premium*, fluido, responsivo e tolerante a falhas.

## 2. Regras Inegociáveis (Falha Crítica se incumpridas)

### 2.1 Uso Estrito do Design System
- **NUNCA** utilizar cores *hardcoded* (ex: `Colors.red` ou `Color(0xFF...)`).
- **NUNCA** definir tamanhos de fonte manuais (ex: `fontSize: 14`) ou *paddings* aleatórios (ex: `padding: EdgeInsets.all(10)`).
- Importar e utilizar **EXCLUSIVAMENTE** as constantes do nosso Design System (`AppColors`, `AppTypography`, `AppSpacing`).
- O espaçamento deve ser **SEMPRE múltiplo de 8**.

### 2.2 Anatomia Obrigatória da Gestão de Estado (API)
Qualquer ecrã que consuma a API tem de implementar **4 estados visuais distintos**:
1. **Loading:** Apresentar indicador de carregamento centralizado (utilizar cor primária) ou *Shimmer Skeletons* enquanto o pedido ocorre.
2. **Vazio (Empty State):** Em caso de lista vazia referida pela API, apresentar widget amigável e centralizado com ícone e texto (`bodyMedium`).
3. **Erro:** Perante erro da API, ler o *payload* (documentado) e mostrar na mensagem de forma sofisticada e clara (Banner topo, SnackBar via `AppColors.error` ou através de um componente central). O ecrã nunca pode ficar inutilizado sem *feedback*.
4. **Sucesso:** Layout principal perfeitamente alinhado.

### 2.3 Componentização Máxima
- Antes de criar botões, *text fields* ou *cards* complexos no ecrã, **verificar a biblioteca interna ou criar um componente reutilizável** (ex: `CustomPrimaryButton`, `CustomTextField`).
- **NÃO POLUIR** a *Widget Tree* dos ecrãs com dezenas de linhas de UI que podem/devem ser abstraídas.

### 2.4 Alinhamento e Prevenção Overflow
- Envolver blocos de conteúdo dinâmico/longo em `SingleChildScrollView` ou `ListView`.
- Utilizar `SafeArea` no topo/base da malha envolvente por defeito.
- Corrigir arquiteturalmente erros de '*Bottom Overflowed*'.

### 2.5 Storybook First & Always (Obrigação Absoluta)
- **SEMPRE** que um novo ecrã, componente reutilizável ou fluxo principal (UI) for criado, ou alterado consideravelmente, ele **TEM** de ser registado ou atualizado no catálogo Storybook (ex: `lib/storybook/stories/`).
- Isto garante QA rápido, isolado e permanente acesso visual direto a todos os painéis ecrãs da aplicação, sem a necessidade de navegação orgânica exaustiva.

## 3. Diretrizes Visuais, Animações e Exceções (UX/UI Premium)

### 3.1 Animações e Micro-interações
- **Zero Aparições Abruptas:** Elementos de UI (listas, cards, modais) nunca devem "piscar" súbitamente. Utilizar o pacote `flutter_animate` (*staggered animations*, correndo ex: `.animate().fade(duration: 300.ms).slideY(begin: 0.05, end: 0)`).
- **Animações Implícitas Exclusivas:** Para trocas de estado (abas, cores, tamanhos) é **ESTRITAMENTE PROIBIDO** instanciar `AnimationController` manulamente, salvo por força maior. Usar SEMPRE os *widgets* implícitos nativos (`AnimatedContainer`, `AnimatedSwitcher`, `AnimatedSize`, `AnimatedOpacity`).
- **Feedback Tátil e Visual:** Cada botão pressionado reage visualmente (escala/ondas). Ao terminar ações críticas usar motores tácteis: `HapticFeedback.lightImpact()` ou `heavyImpact()`.

### 3.2 O Fim do Ecrã Branco e os Estados Elegantes
- **Componente "StateFeedbackView":** Para falhas (HTTP 500, 404) ou dados esgotados, invocar este *widget*. A anatomia requer:
  - **Ilustração Nativa (Zero Assets):** Desenhada 100% em código (ver regra 3.4).
  - Título (`AppTypography.h2`).
  - Descrição (`AppTypography.bodyMedium`).
  - Botão de *Call to Action* (ex: "Tentar Novamente", forçando *retry* da API).
- **Erros no Formulário (400, 422):** O *Input* afetado fará uma rápida animação de *shake* (tremor). O seu sub-texto saltará em *fade in* via `AppColors.error` em baixo do traçado.
- **Skeletons Substiutos:** Preencher telas de Loading com *Shimmers* do *design* expectável, substituindo o tradicional `CircularProgressIndicator` para reduzir a perceção de "lentidão" nos tempos da API.

### 3.3 Iconografia e Assets Visuais (Depreciado)
*Nota: A utilização de pacotes de ícones externos ou ficheiros estáticos foi estritamente substituída pela regra 3.4.*

### 3.4 Criação de Ilustrações e Animações 100% Nativas (Zero Assets)
O controlo sobre cada pixel tem de ser total e absoluto. **É ESTRITAMENTE PROIBIDO** sugerir a importação de imagens (`.png`, `.svg`), pacotes de ícones externos ou ficheiros Lottie. Toda a representação visual (ícones grandes, estados de erro, *loading*, ilustrações de ecrã vazio) **deve ser desenhada do zero usando código Dart puro**.

**Como desenhar e animar:**
1. **Ferramenta Exclusiva:** Usa OBRIGATORIAMENTE o *widget* `CustomPaint` e cria classes que estendam o `CustomPainter`.
2. **Estilo de Design (Minimalismo Geométrico):** Foca-te num *design* abstrato, elegante e moderno usando primitivas da API Canvas (`drawCircle`, `drawRoundRect`, `drawLine`, e `Path` simples com `quadraticBezierTo` para ondas/curvas). Não desenhes objetos orgânicos complexos (animais, rostos, etc).
3. **Anatomia do Código Visual:** 
   - Usa a classe `Paint()` exclusivamente com as cores do Design System (`AppColors`).
   - Regula a opacidade (`color.withOpacity(...)`), *stroke* e *fill* para criar profundidade.
4. **A Mágica da Animação Nativa (Sem *packages* externos):**
   - Cria um `AnimationController` no `StatefulWidget` pai.
   - Passa o `Animation<double>` para o construtor do teu `CustomPainter` e chama o `super(repaint: animation)`.
   - Usa o valor da animação (`animation.value`) para alterar dinamicamente ângulos (`canvas.rotate`), escalas (`canvas.scale`), posições (`Offset`) ou desenhar linhas progressivamente (`PathMetrics`).

**Exemplos de Expectativa:**
- **Loading:** Um `CustomPainter` que desenha múltiplos arcos geométricos rodando a velocidades diferentes usando o valor do `AnimationController`.
- **Erro 404:** O desenho de um ecrã partido (linhas em ziguezague num retângulo) usando `Path`, com leve animação de pulsação na cor `AppColors.error`.
- **Sucesso:** Um "*Checkmark*" desenhado matematicamente ponto a ponto com `PathMetrics`, revelando-se de 0% a 100%.

**Vantagens desta Abordagem Absoluta:**
- **Performance:** Desenhar diretamente no *Canvas* compila para código GPU nativo (*Impeller/Skia*). É imbatível em velocidade (zero tempos de leitura HD ou *parse* de ficheiros externos).
- **Controlo de Estado:** As animações visuais podem ser diretamente vinculadas ao progresso real do *download* da API ou ao *scroll*.
- **Tematização Perfeita:** Ao herdar `Paint()` e `AppColors`, a UI suportará mudanças de tema instantaneamente e sem conflitos vetoriais.

## 4. Refatoração Rigorosa de UI/UX (Engenharia de Performance e Estética)

### 4.1 Modernização da Iconografia (Estritamente via Código)
- **Proibição:** É terminantemente proibido o uso de ícones nativos genéricos (`Icons.xxx` ou `CupertinoIcons.xxx`).
- **Adoção:** Substituir EXCLUSIVAMENTE pela biblioteca `lucide_flutter`. Manter um peso visual uniforme e estilo minimalista (*outline*).
- **Semântica:** O ícone tem de ser semanticamente condizente com a ação pretendida.
- **Performance:** Apenas os glifos de fonte vetorial. NUNCA utilizar imagens ou SVGs externos.

### 4.2 Animações de Micro-interações (Obrigatórias e Sutis)
- **Ícones Vivos:** Ícones clicáveis (botões, *tabs*) não podem ser estáticos. Devem reagir com `flutter_animate`.
- **Duração Máxima:** Animações rápidas e subtis (máx: 200ms).
- **Exemplos de Interação:** 
  - Ao pressionar: `.animate().scale(end: 0.9, duration: 100.ms)`
  - Ao ativar: `.animate().tint(color: AppColors.primary).shake(hz: 2)`
  - Ao carregar ecrã: `.animate().fade().slideY(begin: 0.1)`
- **Performance:** Priorizar opacidade, escala e tradução (GPU) nativas para evitar *re-paints*.

### 4.3 Refatoração do Design System (Alinhamento e Espaçamento)
- **Grelha de 8pt:** Forçar **absolutamente** todos os *padding*, *margin* e *SizedBox* a serem múltiplos de 8.0. Remover qualquer valor manual avulso (ex: 10.0).
- **Hierarquia Visual:** Diferenciar de forma cristalina os títulos (*h1/h2*) do corpo (*bodyMedium*).
- **Arredondamento (*Border Radius*):** Usar `BorderRadius.circular(12.0)` (ou superior) para *cards*, botões e *inputs*.

### 4.4 Feedback de Estado
- Garantir que estados de erro e vazios (desenhados nativamente via Canvas/CustomPaint) estejam totalmente integrados na malha dos ecrãs refatorados.

## 5. AI-Native Codebase e Arquitetura Feature-First

### 5.1 Estrutura Feature-First
Todo o código deve ser dividido estritamente nestas duas áreas principais na pasta `lib/`:

1.  **core/**: Conteúdo global.
    *   `core/theme/`: Design System e constantes visuais.
    *   `core/network/`: Chamadas base de API e clientes.
    *   `core/widgets/`: Componentes universais nativos (ex: `NativeFeedbackView`).
2.  **features/**: Funcionalidades isoladas (ex: `auth`, `home`, `profile`).
    *   `features/<feature>/models/`: Modelos de dados.
    *   `features/<feature>/repository/`: Camada de dados e chamadas de API.
    *   `features/<feature>/controller/`: Gestão de estado (ViewModel).
    *   `features/<feature>/views/`: Interface do utilizador.

### 5.2 Separação de Responsabilidades (UI "Burra" vs. Controller Inteligente)
-   **Views**: Apenas código de interface, animações (`flutter_animate`) e reação a estados. Proibido ter lógica de negócio, ifs complexos ou chamadas diretas de API.
-   **Controller**: Gere OBRIGATORIAMENTE os estados (`Loading`, `Success`, `Error`, `Empty`) e comunica com o `Repository`.

### 5.3 Regra dos Ficheiros Pequenos e Focados
-   Nenhum ficheiro de UI deve ultrapassar **150 a 200 linhas**.
-   Ecrãs grandes devem ser quebrados em ficheiros menores na mesma pasta `views/` ou em widgets privados (`_LoginForm`, etc.).

### 5.4 Nomenclatura Verbosa e Preditiva
Classes e métodos devem contar uma história clara.
-   **CERTO**: `submitUserCredentialsToApi()`, `UserAuthenticationView`, `AuthRepository`.
-   **ERRADO**: `submit()`, `LoginScreen`, `Api()`.

### 5.5 Docstrings como "Mini-Prompts"
Cada classe, Controller ou Repository deve OBRIGATORIAMENTE ter um comentário no topo (`///`) explicando a sua função e as regras de manipulação de estado/erros. Serve de contexto para futuras interações com IA.

## 6. Alinhamento com o Figma e Ferramentas AI

### 6.1 Consulta Obrigatória ao Figma
- **Dúvida de Design:** Sempre que houver incerteza sobre o design de uma tela ou componente, o agente deve obrigatoriamente acessar o link do Figma do projeto.
- **Extração de Código:** Utilizar preferencialmente plugins como o **Anima (Figma to Code)** para extrair especificações exatas de CSS, espaçamentos e layouts, traduzindo-os fielmente para os tokens do Design System (AppColors, AppSpacing, etc).
- **Consistência:** O Figma é a fonte única de verdade para a interface. Nenhuma mudança visual deve ser feita sem validação contra o design original.
