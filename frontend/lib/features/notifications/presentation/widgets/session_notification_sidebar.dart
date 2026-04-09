import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teste/features/notifications/presentation/providers/session_notification_provider.dart';

class SessionNotificationSidebar extends ConsumerWidget {
  final VoidCallback? onClose;
  final bool showCloseButton;

  const SessionNotificationSidebar({
    super.key,
    this.onClose,
    this.showCloseButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(sessionNotificationFeedProvider);
    final headerTitle = _copy(
      context,
      pt: 'Alertas da sessão',
      en: 'Session alerts',
      es: 'Alertas de la sesion',
    );
    final headerSubtitle = _copy(
      context,
      pt: 'Tudo o que acabou de acontecer',
      en: 'Everything that just happened',
      es: 'Todo lo que acaba de pasar',
    );
    final clearLabel = _copy(
      context,
      pt: 'Limpar',
      en: 'Clear',
      es: 'Limpiar',
    );
    final emptyStateMessage = _copy(
      context,
      pt: 'Quando algo importante acontecer, o aviso aparece aqui na hora.',
      en: 'When something important happens, the alert appears here immediately.',
      es: 'Cuando ocurra algo importante, la alerta aparecera aqui al instante.',
    );

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: const Color(0xFF0A121B),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          headerSubtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.58),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (showCloseButton)
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${notifications.length} alerta${notifications.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: notifications.isEmpty
                        ? null
                        : () => ref
                            .read(sessionNotificationFeedProvider.notifier)
                            .clear(),
                    child: Text(clearLabel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              emptyStateMessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.54),
                                    height: 1.5,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111A24),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.body,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.76),
                                      height: 1.45,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _relativeLabel(context, item.timestamp),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.46),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _copy(
    BuildContext context, {
    required String pt,
    required String en,
    required String es,
  }) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'en':
        return en;
      case 'es':
        return es;
      default:
        return pt;
    }
  }

  String _relativeLabel(BuildContext context, DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return _copy(context, pt: 'agora', en: 'now', es: 'ahora');
    }
    if (difference.inHours < 1) {
      return _copy(
        context,
        pt: 'há ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}',
        en: '${difference.inMinutes} min ago',
        es: 'hace ${difference.inMinutes} minuto${difference.inMinutes == 1 ? '' : 's'}',
      );
    }
    if (difference.inDays < 1) {
      return _copy(
        context,
        pt: 'há ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}',
        en: '${difference.inHours} hr ago',
        es: 'hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}',
      );
    }
    return _copy(
      context,
      pt: 'há ${difference.inDays} dia${difference.inDays == 1 ? '' : 's'}',
      en: '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago',
      es: 'hace ${difference.inDays} dia${difference.inDays == 1 ? '' : 's'}',
    );
  }
}
