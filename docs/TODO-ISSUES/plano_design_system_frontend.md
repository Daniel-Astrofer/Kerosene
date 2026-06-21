# Plano de Implementação de Frontend Profissional

## Objetivo

Criar um Design System escalável, consistente e profissional, inspirado em aplicativos como iFood, Uber, Airbnb e WhatsApp.

---

# Fase 1 — Fundação do Design System

Estrutura inicial:

```text
lib/
└── design_system/
    ├── colors.dart
    ├── typography.dart
    ├── spacing.dart
    ├── radius.dart
    ├── shadows.dart
    ├── icons.dart
    ├── motion.dart
    ├── theme.dart
    ├── buttons/
    ├── cards/
    └── inputs/
```

Objetivos:

- Eliminar valores aleatórios.
- Centralizar todas as decisões visuais.
- Garantir consistência em todo o projeto.

---

# Fase 2 — Design Tokens

## Cores

Criar:

```dart
class AppColors {
  static const primary = Color(...);
  static const secondary = Color(...);

  static const success = Color(...);
  static const warning = Color(...);
  static const error = Color(...);

  static const background = Color(...);
  static const surface = Color(...);

  static const textPrimary = Color(...);
  static const textSecondary = Color(...);
}
```

Regras:

- Nunca usar hexadecimal diretamente nas telas.
- Sempre utilizar AppColors.

---

## Espaçamentos

Criar:

```dart
class Spacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

Regras:

- Nunca usar números aleatórios.
- Trabalhar em múltiplos de 4 ou 8.

---

## Bordas

```dart
class Radius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}
```

---

## Sombras

```dart
class AppShadows {
  ...
}
```

Definir níveis:

- Small
- Medium
- Large

---

# Fase 3 — Sistema Tipográfico

Criar:

```dart
class AppTypography {
  static const display;
  static const h1;
  static const h2;
  static const h3;
  static const body;
  static const caption;
}
```

Exemplo:

```text
Display = 40
H1 = 32
H2 = 24
H3 = 20
Body = 16
Caption = 12
```

Regras:

- Nunca definir tamanho de fonte diretamente.
- Utilizar apenas estilos oficiais.

---

# Fase 4 — Sistema de Ícones

Escolher apenas UMA biblioteca.

Sugestões:

- Material Symbols
- Lucide
- Phosphor

Criar:

```dart
class AppIcons {
  static const home;
  static const wallet;
  static const settings;
  static const profile;
}
```

Regras:

- Não misturar bibliotecas.
- Centralizar toda a iconografia.

---

# Fase 5 — Motion Design

Criar:

```dart
class Motion {
  static const fast =
      Duration(milliseconds: 150);

  static const normal =
      Duration(milliseconds: 250);

  static const slow =
      Duration(milliseconds: 400);
}
```

Curvas padrão:

```dart
Curves.easeOut
Curves.easeInOut
Curves.fastOutSlowIn
```

Regras:

- Nunca inventar tempos por tela.
- Utilizar apenas durações oficiais.

---

# Fase 6 — Biblioteca de Componentes

## Botão

Criar:

```text
AppButton
```

Estados:

- Normal
- Hover
- Focus
- Pressed
- Disabled
- Loading

---

## Inputs

Criar:

```text
AppTextField
```

Estados:

- Normal
- Focus
- Error
- Disabled

---

## Cards

Criar:

```text
AppCard
```

Variantes:

- Small
- Medium
- Large

---

## Bottom Sheets

Criar componente reutilizável.

---

## Dialogs

Criar componente reutilizável.

---

# Fase 7 — Feedback Visual

Todo elemento clicável deve responder visualmente.

Exemplos:

- Ripple
- Opacidade
- Escala
- Destaque

Nunca permitir:

```text
Clique sem feedback.
```

---

# Fase 8 — Animações de Estado

Implementar:

## Botão → Loading

```text
Enviar
↓
Loading
↓
Sucesso
```

## Card → Tela

Hero Animation.

## Lista → Atualização

AnimatedSwitcher.

## Conteúdo → Loading

Skeleton Loading.

---

# Fase 9 — Tema Global

Criar:

```dart
ThemeData appTheme
```

Controlar:

- Cores
- Tipografia
- Botões
- Inputs
- Cards
- Navegação

Tudo deve passar pelo tema.

---

# Fase 10 — Auditoria de Consistência

Antes de cada release:

Checklist:

- Nenhuma cor hardcoded.
- Nenhuma fonte hardcoded.
- Nenhum espaçamento aleatório.
- Nenhum ícone fora do padrão.
- Nenhuma animação fora do sistema.
- Nenhum componente duplicado.

---

# Meta Final

Ao concluir todas as fases:

- Interface consistente.
- Escalabilidade para centenas de telas.
- Fácil manutenção.
- Aparência profissional.
- Base comparável às práticas utilizadas em grandes aplicativos.

Esse Design System deve ser tratado como parte central do produto, não como um detalhe visual.
