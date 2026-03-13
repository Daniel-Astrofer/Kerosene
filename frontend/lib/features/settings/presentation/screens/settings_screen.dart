import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/cyber_theme.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/currency_provider.dart';
import '../../../../core/providers/price_provider.dart';
import '../../../../core/providers/biometric_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider).locale;
    final currentCurrency = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: CyberTheme.bgDeep,
      body: Container(
        decoration: const BoxDecoration(gradient: CyberTheme.bgGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ─────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CyberTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CyberTheme.border,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: CyberTheme.textPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizations.of(context)!.settingsTitle,
                      style: CyberTheme.heading(size: 22),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Language ──────────────────
                      _SectionTitle(
                        title: AppLocalizations.of(context)!.selectLanguage,
                      ),
                      const SizedBox(height: 14),
                      _SettingsOptionTile(
                        label: 'English',
                        leading: '🇺🇸',
                        isSelected: currentLocale.languageCode == 'en',
                        accentColor: CyberTheme.neonCyan,
                        onTap: () => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('en')),
                      ),
                      _SettingsOptionTile(
                        label: 'Português',
                        leading: '🇧🇷',
                        isSelected: currentLocale.languageCode == 'pt',
                        accentColor: CyberTheme.neonCyan,
                        onTap: () => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('pt')),
                      ),
                      _SettingsOptionTile(
                        label: 'Español',
                        leading: '🇪🇸',
                        isSelected: currentLocale.languageCode == 'es',
                        accentColor: CyberTheme.neonCyan,
                        onTap: () => ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('es')),
                      ),

                      const SizedBox(height: 30),

                      // ─── Currency ──────────────────
                      _SectionTitle(
                        title: AppLocalizations.of(context)!.selectCurrency,
                      ),
                      const SizedBox(height: 14),
                      _CurrencyOptionTile(
                        ref: ref,
                        currency: Currency.usd,
                        label: 'USD — Dollar',
                        symbol: '\$',
                        isSelected: currentCurrency == Currency.usd,
                      ),
                      _CurrencyOptionTile(
                        ref: ref,
                        currency: Currency.brl,
                        label: 'BRL — Real',
                        symbol: 'R\$',
                        isSelected: currentCurrency == Currency.brl,
                      ),
                      _CurrencyOptionTile(
                        ref: ref,
                        currency: Currency.eur,
                        label: 'EUR — Euro',
                        symbol: '€',
                        isSelected: currentCurrency == Currency.eur,
                      ),

                      const SizedBox(height: 30),

                      // ─── Security ──────────────────
                      const _SectionTitle(title: 'SECURITY'),
                      const SizedBox(height: 14),
                      Consumer(
                        builder: (context, ref, child) {
                          final bioState = ref.watch(biometricProvider);

                          if (!bioState.isSupported) {
                            return const SizedBox.shrink();
                          }

                          return _CyberSwitchTile(
                            title: 'Biometric Authentication',
                            value: bioState.isEnabled,
                            onChanged: (value) {
                              ref
                                  .read(biometricProvider.notifier)
                                  .toggleBiometric(value);
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Section Title
// ═══════════════════════════════════════════════
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.jetBrainsMono(
        color: CyberTheme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2.0,
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Language Option Tile
// ═══════════════════════════════════════════════
class _SettingsOptionTile extends StatelessWidget {
  final String label;
  final String leading;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _SettingsOptionTile({
    required this.label,
    required this.leading,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.06)
                  : CyberTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.5)
                    : CyberTheme.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(leading, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? accentColor : CyberTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: accentColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Currency Option Tile
// ═══════════════════════════════════════════════
class _CurrencyOptionTile extends StatelessWidget {
  final WidgetRef ref;
  final Currency currency;
  final String label;
  final String symbol;
  final bool isSelected;

  static const _btcOrange = Color(0xFFF7931A);

  const _CurrencyOptionTile({
    required this.ref,
    required this.currency,
    required this.label,
    required this.symbol,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              ref.read(currencyProvider.notifier).setCurrency(currency),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? _btcOrange.withValues(alpha: 0.06)
                  : CyberTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? _btcOrange.withValues(alpha: 0.5)
                    : CyberTheme.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _btcOrange.withValues(alpha: 0.15)
                        : CyberTheme.bgInput,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    symbol,
                    style: GoogleFonts.jetBrainsMono(
                      color: isSelected ? _btcOrange : CyberTheme.textSecondary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? _btcOrange : CyberTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _btcOrange,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Switch Tile (Biometric)
// ═══════════════════════════════════════════════
class _CyberSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CyberSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: CyberTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CyberTheme.border, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CyberTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: CyberTheme.neonCyan,
            activeTrackColor: CyberTheme.neonCyan.withValues(alpha: 0.3),
            inactiveThumbColor: CyberTheme.textMuted,
            inactiveTrackColor: CyberTheme.border,
          ),
        ],
      ),
    );
  }
}
