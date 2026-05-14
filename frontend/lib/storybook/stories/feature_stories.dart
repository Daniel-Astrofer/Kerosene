// Kerosene Storybook — Miscellaneous Feature Stories
// Contains sovereignty status, deposit list, add funds, and other feature screens.
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:teste/features/security/presentation/screens/sovereignty_status_screen.dart';
import 'package:teste/features/transactions/presentation/screens/deposits_screen.dart';

/// Returns miscellaneous feature stories.
List<Story> featureStories() {
  return [
    Story(
      name: 'Features/Sovereignty Status',
      description: 'Node sovereignty and decentralization score dashboard.',
      builder: (context) => const SovereigntyStatusScreen(),
    ),
    Story(
      name: 'Features/Deposits List',
      description: 'History of all BTC deposits received.',
      builder: (context) => const DepositsScreen(),
    ),
  ];
}
