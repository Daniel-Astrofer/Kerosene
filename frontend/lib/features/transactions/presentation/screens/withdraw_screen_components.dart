part of 'withdraw_screen.dart';

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;
  final bool monospace;
  final int maxLines;

  const _FeeRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
    this.monospace = false,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    const textColor = receiveFlowTextColor;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: receiveFlowMutedTextColor,
                  fontWeight: FontWeight.w400,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor ?? textColor,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              fontFamily: monospace ? 'IBMPlexSansHebrew' : null,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeeModeOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String body;
  final IconData icon;
  final VoidCallback onTap;

  const _FeeModeOption({
    required this.selected,
    required this.title,
    required this.body,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? receiveFlowTextColor : receiveFlowBorderStrongColor;
    final iconColor =
        selected ? receiveFlowTextColor : receiveFlowMutedTextColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? receiveFlowPanelAltColor : receiveFlowPanelColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: receiveFlowTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: receiveFlowMutedTextColor,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              selected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 18,
              color: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}
