import 'package:flutter/material.dart';
import 'package:kerosene/core/copy/kerosene_ui_copy.dart';
import 'package:kerosene/core/theme/kerosene_brand_tokens.dart';
import 'package:kerosene/design_system/icons.dart';

typedef DeferredWidgetBuilder = Widget Function(BuildContext context);

class DeferredPage extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final DeferredWidgetBuilder builder;
  final Widget? loading;

  const DeferredPage({
    super.key,
    required this.loadLibrary,
    required this.builder,
    this.loading,
  });

  @override
  State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  late final Future<void> _libraryFuture;

  @override
  void initState() {
    super.initState();
    _libraryFuture = widget.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return widget.loading ?? const _DeferredPageLoadingView();
        }
        if (snapshot.hasError) {
          return _DeferredPageErrorView(error: snapshot.error);
        }
        return widget.builder(context);
      },
    );
  }
}

class _DeferredPageLoadingView extends StatelessWidget {
  const _DeferredPageLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: KeroseneBrandTokens.backgroundSoft,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _DeferredPageErrorView extends StatelessWidget {
  final Object? error;

  const _DeferredPageErrorView({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KeroseneBrandTokens.backgroundSoft,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                KeroseneIcons.serverUnavailable,
                color: KeroseneBrandTokens.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 12),
              const Text(
                KeroseneUiCopy.deferredLoadFailure,
                style: TextStyle(color: KeroseneBrandTokens.textPrimary),
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  KeroseneUiCopy.deferredLoadDetails,
                  style: const TextStyle(
                    color: KeroseneBrandTokens.textMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
