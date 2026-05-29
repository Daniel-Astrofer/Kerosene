import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kerosene/core/theme/app_spacing.dart';

/// Glass-morphism top bar with blurred background.
class KeroseneHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const KeroseneHeader({
    super.key,
    this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: preferredSize.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    if (showBackButton)
                      IconButton(
                        onPressed:
                            onBackPressed ?? () => Navigator.pop(context),
                        icon: Icon(
                          LucideIcons.arrowLeft,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .onPrimary
                              .withValues(alpha: 0.05),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                        ),
                      )
                    else
                      const SizedBox(
                          width:
                              48), // Spacer to balance title alignment if needed

                    const SizedBox(width: AppSpacing.sm),

                    Expanded(
                      child: title != null
                          ? Text(
                              title!,
                              style: Theme.of(context).textTheme.titleMedium!,
                              textAlign: TextAlign.center,
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    if (actions != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      )
                    else
                      const SizedBox(
                          width: 48), // Spacer to balance title alignment
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
