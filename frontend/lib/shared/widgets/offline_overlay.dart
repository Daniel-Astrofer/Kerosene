import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/network_status_provider.dart';

class OfflineOverlay extends ConsumerWidget {
  final Widget child;

  const OfflineOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(networkStatusProvider);

    return RepaintBoundary(
      child: Stack(
        children: [
          child,
          if (!isOnline)
            Positioned.fill(
              child: IgnorePointer(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(networkStatusProvider.notifier)
                          .checkConnection();
                    },
                    color: Colors.redAccent,
                    backgroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.8),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(alpha: 0.25),
                                ),
                              ),
                              child: const Icon(
                                Icons.wifi_off_rounded,
                                size: 56,
                                color: Colors.redAccent,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'SEM CONEXAO',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                fontFamily: 'monospace',
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Nao foi possivel confirmar a conexao agora.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 50),
                            const Text(
                              'Arraste para tentar novamente',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
