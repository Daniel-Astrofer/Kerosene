import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/presentation/widgets/glass_container.dart';
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
      backgroundColor: const Color(0xFF000000),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF101018)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      AppLocalizations.of(context)!.settingsTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Language Section
                      _buildSectionTitle(
                        context,
                        AppLocalizations.of(context)!.selectLanguage,
                      ),
                      const SizedBox(height: 16),
                      _buildLanguageOption(
                        context,
                        ref,
                        'en',
                        'English',
                        '🇺🇸',
                        currentLocale.languageCode == 'en',
                      ),
                      _buildLanguageOption(
                        context,
                        ref,
                        'pt',
                        'Português',
                        '🇧🇷',
                        currentLocale.languageCode == 'pt',
                      ),
                      _buildLanguageOption(
                        context,
                        ref,
                        'es',
                        'Español',
                        '🇪🇸',
                        currentLocale.languageCode == 'es',
                      ),

                      const SizedBox(height: 32),

                      // Currency Section
                      _buildSectionTitle(
                        context,
                        AppLocalizations.of(context)!.selectCurrency,
                      ),
                      const SizedBox(height: 16),
                      _buildCurrencyOption(
                        context,
                        ref,
                        Currency.usd,
                        'USD - Dollar',
                        '\$',
                        currentCurrency == Currency.usd,
                      ),
                      _buildCurrencyOption(
                        context,
                        ref,
                        Currency.brl,
                        'BRL - Real',
                        'R\$',
                        currentCurrency == Currency.brl,
                      ),
                      _buildCurrencyOption(
                        context,
                        ref,
                        Currency.eur,
                        'EUR - Euro',
                        '€',
                        currentCurrency == Currency.eur,
                      ),

                      const SizedBox(height: 32),

                      // Security Section
                      _buildSectionTitle(
                        context,
                        "SECURITY", // TODO: Add to l10n
                      ),
                      const SizedBox(height: 16),
                      Consumer(
                        builder: (context, ref, child) {
                          final bioState = ref.watch(biometricProvider);

                          if (!bioState.isSupported) {
                            return const SizedBox.shrink();
                          }

                          return _buildSwitchOption(
                            context,
                            "Biometric Authentication", // TODO: Add to l10n
                            bioState.isEnabled,
                            (value) {
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WidgetRef ref,
    String code,
    String name,
    String flag,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        blur: 10,
        opacity: isSelected ? 0.1 : 0.03,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: const Color(0xFF00FF94), width: 2)
            : null,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(Locale(code));
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF00FF94)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF00FF94),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(
    BuildContext context,
    WidgetRef ref,
    Currency currency,
    String name,
    String symbol,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        blur: 10,
        opacity: isSelected ? 0.1 : 0.03,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(
                color: const Color(
                  0xFFF7931A,
                ), // Orange for currency/bitcoin vibe
                width: 2,
              )
            : null,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(currencyProvider.notifier).setCurrency(currency);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF7931A).withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      symbol,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFF7931A)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFFF7931A)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFF7931A),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        blur: 10,
        opacity: 0.03,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF00FF94),
              activeTrackColor: const Color(0xFF00FF94).withValues(alpha: 0.3),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
