# Kerosene Frontend Design System

This is the implementation contract for agents and developers creating or
refactoring Flutter screens in `frontend/lib`.

## Source Of Truth

- Typography: `frontend/lib/core/theme/app_typography.dart`
- Theme: `frontend/lib/core/theme/app_theme.dart`
- Monochrome surfaces: `frontend/lib/core/theme/monochrome_theme.dart`
- Spacing: `frontend/lib/core/theme/app_spacing.dart`
- Localization: `frontend/lib/core/l10n/*.arb`
- Reference screen: `frontend/lib/core/theme/design_system_template.dart`

## Typography

Only three font families are allowed:

- `Inter`: body text, form fields, labels, captions, buttons.
- `IBM Plex Sans Hebrew`: balances, numbers, hashes, technical identifiers,
  dense secondary headings.
- `IBM Plex Serif`: primary h1/display headings.

Use `AppTypography` or `Theme.of(context).textTheme`. Do not introduce
Playfair, Garamond, Space Grotesk, Hubot, Geist, JetBrains Mono, IBM Plex Mono,
generic `monospace`, or any other family.

## Layout And Color

Use `AppSpacing` for all gaps, padding and margins. Prefer the 8px grid tokens
already exposed by the app.

Use `Theme.of(context).colorScheme` and `monochrome_theme.dart` tokens for
surfaces, borders and text. `AppColors.primary`, `success`, `warning` and
`error` are semantic accents, not a license to create new palettes.

## L10n

Every user-visible label, heading, button text, empty state, error and hint must
come from `context.tr.<key>`.

When adding a string:

1. Add the key to `app_en.arb`, `app_pt.arb` and `app_es.arb`.
2. Run `flutter gen-l10n` from `frontend/`.
3. Use the generated getter through `context.tr`.

Only dynamic data values such as BTC amounts, hashes, txids and generated
addresses may be inline constants in a demo/template.

## Screen Creation Checklist

- Start from `DesignSystemTemplateScreen` when unsure.
- Use `Scaffold`/surface colors from the active theme.
- Use `AppTypography.h1` or `headlineLarge` only for true primary titles.
- Use `AppTypography.bodyMedium` or theme body slots for regular copy.
- Use `AppTypography.technicalMono` or `numericFontFamily` for hashes, PINs,
  invoice strings, txids and balances.
- Keep buttons from the app theme or `monochromeFilledButtonStyle` /
  `monochromeOutlinedButtonStyle`.
- Keep strings in l10n before committing UI code.
