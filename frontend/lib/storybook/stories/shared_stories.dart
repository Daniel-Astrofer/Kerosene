// Kerosene Storybook — Shared Custom Widgets
// Contains complex visual components from lib/shared/widgets/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:teste/core/theme/app_spacing.dart';
import 'package:teste/shared/widgets/brushed_metal_container.dart';
import 'package:teste/shared/widgets/draggable_card_3d.dart';
import 'package:teste/shared/widgets/offline_overlay.dart';
import 'package:teste/core/providers/network_status_provider.dart';
import 'package:teste/features/wallet/domain/entities/wallet.dart';
import 'package:teste/features/wallet/presentation/widgets/wallet_credit_card.dart';

// Mock Notifier for Storybook
class _MockNetworkStatusNotifier extends NetworkStatusNotifier {
  final bool _isOffline;
  _MockNetworkStatusNotifier(this._isOffline);

  @override
  bool build() => !_isOffline;
}

List<Story> sharedStories() {
  return [
    Story(
      name: 'Shared/Glassmorphism/Brushed Metal Container',
      builder: (context) {
        final materialId = context.knobs
            .slider(label: 'Material ID', initial: 0.0, min: 0, max: 3);
        final opacity = context.knobs
            .slider(label: 'Opacity', initial: 0.1, min: 0, max: 1);
        return Center(
          child: Container(
            width: 300,
            height: 200,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: BrushedMetalContainer(
              width: 300,
              height: 200,
              materialId: materialId,
              baseColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: opacity),
              borderRadius: 24.0,
              child: const Center(
                child: Text('BRUSHED METAL SHADER',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        );
      },
    ),
    Story(
      name: 'Shared/Effects/Draggable Card 3D',
      builder: (context) => const Center(
        child: SizedBox(
          width: 300,
          height: 200,
          child: DraggableCard3D(
            child: Card(
              color: Color(0xFF1E293B),
              child: Center(
                child: Text('DRAG ME (3D EFFECT)',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    ),
    Story(
      name: 'Shared/Overlays/Offline Banner',
      builder: (context) {
        final isOffline =
            context.knobs.boolean(label: 'Is Offline', initial: true);
        return ProviderScope(
          overrides: [
            networkStatusProvider
                .overrideWith(() => _MockNetworkStatusNotifier(isOffline)),
          ],
          child: OfflineOverlay(
            child: const Center(child: Text('Background Content')),
          ),
        );
      },
    ),
    Story(
      name: 'Shared/Wallet/Wallet Credit Card (Live Shader)',
      builder: (context) {
        final balance = context.knobs
            .slider(label: 'Balance', initial: 1.25, min: 0, max: 10);
        final colorIndex = context.knobs
            .slider(label: 'Color Index', initial: 0, min: 0, max: 3)
            .toInt();

        final mockWallet = Wallet(
          id: '1',
          name: 'Personal Wallet',
          address: '0x487a32...aeef',
          balance: 1.25,
          derivationPath: "m/84'/0'/0'",
          type: WalletType.nativeSegwit,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return Center(
          child: SizedBox(
            width: 303,
            height: 175,
            child: WalletCreditCard(
              wallet: mockWallet.copyWith(balance: balance),
              colorIndex: colorIndex,
              isSelected: true,
              showDetails: true,
            ),
          ),
        );
      },
    ),
  ];
}
