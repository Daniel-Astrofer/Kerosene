import 'package:flutter/material.dart';
import '../l10n/l10n_extension.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'monochrome_theme.dart';

/// KEROSENE AGENT INSTRUCTION AND REFERENCE SCREEN TEMPLATE
///
/// This file is both a design-system specification and a compilable reference
/// screen. Future agents and developers should follow this pattern when adding
/// or refactoring app screens.
///
/// OFFICIAL TYPOGRAPHY - ONLY 3 FONT FAMILIES ARE ALLOWED
///
/// - Inter: body text, buttons, labels, captions, form fields.
///   Use AppTypography.bodyLarge/bodyMedium/bodySmall/buttonText/caption or the
///   active Theme.of(context).textTheme body/label slots.
///
/// - IBM Plex Sans Hebrew: numerical titles, balances, BTC amounts, hashes,
///   technical data and dense secondary headings.
///   Use AppTypography.h2/h3/number/amountInput/technicalMono.
///
/// - IBM Plex Serif: primary h1/display headings.
///   Use AppTypography.h1 or Theme.of(context).textTheme.displayLarge/headlineLarge.
///
/// Do not introduce Playfair, Garamond, Space Grotesk, Hubot, Geist, JetBrains
/// Mono, generic monospace or any other family outside the three above.
///
/// OTHER RULES
///
/// 1. Internationalization:
///    Never put user-visible raw strings in widgets. Add keys to all ARB files
///    and read them through context.tr.
///
/// 2. Spacing:
///    Use AppSpacing tokens. Avoid ad-hoc padding and gap values.
///
/// 3. Color:
///    Prefer Theme.of(context).colorScheme and monochrome_theme tokens. Use
///    AppColors.primary/success/warning/error only for semantic emphasis.

class DesignSystemTemplateScreen extends StatelessWidget {
  const DesignSystemTemplateScreen({super.key});

  static const String sampleBalance = '0.04269182 BTC';
  static const String sampleAddress =
      'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080';

  @override
  Widget build(BuildContext context) {
    final isAmoled = Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.tr.designSystemTemplateTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              context.tr.designSystemTemplateIdentitySection,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr.designSystemTemplateHeroTitle,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontFamily: AppTypography.serifFontFamily,
                    letterSpacing: 0,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.tr.welcomeSlogan,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            _buildSectionHeader(
              context,
              context.tr.designSystemTemplatePanelsSection,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: monochromePanelDecoration(
                color: isAmoled
                    ? monoSurfaceColor
                    : Theme.of(context).colorScheme.surface,
                borderColor:
                    isAmoled ? monoBorderColor : Theme.of(context).dividerColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr.totalBalance.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: monoMutedTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.security,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    sampleBalance,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontFamily: AppTypography.numericFontFamily,
                          fontWeight: FontWeight.w300,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isAmoled
                          ? monoSurfaceAltColor
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: monoRadius,
                    ),
                    child: Text(
                      sampleAddress,
                      style: AppTypography.technicalMono(
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),
            _buildSectionHeader(
              context,
              context.tr.designSystemTemplateInputSection,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              decoration: monochromeInputDecoration(
                label: context.tr.recipient.toUpperCase(),
                hintText: context.tr.recipientHint,
                prefixIcon: const Icon(Icons.alternate_email, size: 18),
              ),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl2),
            _buildSectionHeader(
              context,
              context.tr.designSystemTemplateButtonsSection,
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () {},
              style: monochromeFilledButtonStyle(emphasis: true),
              child: Text(context.tr.continueButton),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () {},
              style: monochromeOutlinedButtonStyle(),
              child: Text(context.tr.cancel.toUpperCase()),
            ),
            const SizedBox(height: AppSpacing.xl2),
            _buildSectionHeader(
              context,
              context.tr.designSystemTemplateStatusSection,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _buildStatusChip(
                  label: context.tr.confirmed.toUpperCase(),
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildStatusChip(
                  label: context.tr.pending.toUpperCase(),
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                _buildStatusChip(
                  label: context.tr.failed.toUpperCase(),
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String text) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: monoMutedTextColor,
      ),
    );
  }

  Widget _buildStatusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: monoRadius,
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
