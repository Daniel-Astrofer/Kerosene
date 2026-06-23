import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kerosene/core/localization/app_localization_manager.dart';
import 'package:kerosene/core/providers/app_display_preferences_provider.dart';
import 'package:kerosene/core/providers/price_provider.dart';
import 'package:kerosene/core/utils/money_display.dart';
import 'package:kerosene/design_system/kerosene_design_system.dart';

import 'settings_section_components.dart';

class SettingsDisplayPane extends ConsumerWidget {
  const SettingsDisplayPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(appDisplayPreferencesProvider);
    final notifier = ref.read(appDisplayPreferencesProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Idioma e moeda',
          style: AppTypography.newsreader(
            color: KeroseneBrandTokens.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w500,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Configuração global usada por todo o aplicativo. O saldo acompanha a cotação ao vivo; transações históricas preservam o valor do momento do envio ou recebimento.',
          style: AppTypography.inter(
            color: KeroseneBrandTokens.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.55,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(
          title: 'Idioma',
          children: [
            for (final locale in AppLocalizationManager.supportedLocales)
              _DisplayOptionRow(
                icon: KeroseneIcons.language,
                title: _languageName(locale),
                subtitle: _languageSubtitle(locale),
                selected:
                    preferences.locale.languageCode == locale.languageCode,
                onTap: () => notifier.setLocale(locale),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(
          title: 'Moeda principal',
          children: [
            for (final currency in Currency.values)
              _DisplayOptionRow(
                icon: currency == Currency.btc
                    ? KeroseneIcons.bitcoin
                    : KeroseneIcons.fiat,
                title:
                    '${MoneyDisplay.tickerSymbolFor(currency)} ${currency.code}',
                subtitle: _currencySubtitle(currency),
                selected: preferences.currency == currency,
                onTap: () => notifier.setCurrency(currency),
              ),
          ],
        ),
      ],
    );
  }

  static String _languageName(Locale locale) {
    return switch (locale.languageCode) {
      'pt' => 'Português',
      'es' => 'Español',
      _ => 'English',
    };
  }

  static String _languageSubtitle(Locale locale) {
    return switch (locale.languageCode) {
      'pt' => 'Interface em português do Brasil',
      'es' => 'Interfaz en español',
      _ => 'Interface in English',
    };
  }

  static String _currencySubtitle(Currency currency) {
    return switch (currency) {
      Currency.btc => 'Exibe valores diretamente em Bitcoin',
      Currency.usd => 'Dólar americano como moeda de leitura',
      Currency.eur => 'Euro como moeda de leitura',
      Currency.brl => 'Real brasileiro como moeda de leitura',
    };
  }
}

class _DisplayOptionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _DisplayOptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSectionRow(
      icon: selected ? KeroseneIcons.check : icon,
      title: title,
      subtitle: subtitle,
      trailing: SettingsReadonlySwitch(value: selected),
      onTap: onTap,
    );
  }
}
