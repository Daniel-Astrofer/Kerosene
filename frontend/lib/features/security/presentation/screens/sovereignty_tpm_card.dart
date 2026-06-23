import 'package:flutter/material.dart';
import 'package:kerosene/core/l10n/l10n_extension.dart';
import 'package:kerosene/design_system/icons.dart';

import 'sovereignty_kfe_reserve_overview_card.dart';
import 'sovereignty_status_components.dart';

Widget buildTpmCard({
  required BuildContext context,
  required Map<String, dynamic> tpm,
  required SovereigntyCopy copy,
}) {
  final verified = tpm['status'] == 'VERIFIED';
  final chipSubtitle = (tpm['chip'] ?? 'Secure Element').toString();
  final pcrQuoteHashLabel = 'PCR Quote Hash';
  final chipLabel = copy(pt: 'Chip', en: 'Chip', es: 'Chip');
  final chipValue = (tpm['chip'] ?? 'Generic TPM').toString();

  return SecurityStatusCard(
    icon: KeroseneIcons.database,
    title: context.tr.hardwareAttestation,
    subtitle: chipSubtitle,
    statusOk: verified,
    statusLabel: tpm['status'] ?? 'UNKNOWN',
    rows: [
      SecurityInfoRow(
        label: copy(
          pt: 'Última validação',
          en: 'Last validation',
          es: 'Última validación',
        ),
        value: '${tpm['lastValidatedSecondsAgo'] ?? 0}s',
        isHighlight: (tpm['lastValidatedSecondsAgo'] ?? 99) < 12,
      ),
      SecurityInfoRow(
        label: copy(
          pt: 'Verificações totais',
          en: 'Total checks',
          es: 'Verificaciones totales',
        ),
        value: '${tpm['totalChecks'] ?? 0}',
      ),
      SecurityInfoRow(
        label: pcrQuoteHashLabel,
        value: tpm['quoteHash'] ?? '0x...',
        isMono: true,
      ),
      SecurityInfoRow(
        label: chipLabel,
        value: chipValue,
      ),
    ],
  );
}
