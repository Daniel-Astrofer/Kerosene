part of 'home_screen.dart';

class _HomeBottomNavigationOverlay extends StatelessWidget {
  final AppPrimaryDestination currentDestination;

  const _HomeBottomNavigationOverlay({required this.currentDestination});

  static const List<AppPrimaryDestination> _orderedDestinations = [
    AppPrimaryDestination.home,
    AppPrimaryDestination.card,
    AppPrimaryDestination.history,
    AppPrimaryDestination.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          SafeArea(
            top: false,
            minimum: EdgeInsets.fromLTRB(0, 0, _homeSize(24), _homeSize(32)),
            child: Align(
              alignment: Alignment.bottomRight,
              child: _HomeFloatingMenuButton(
                currentDestination: currentDestination,
                destinations: _orderedDestinations,
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: EdgeInsets.only(bottom: _homeSize(8)),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: _homeSize(128),
                height: _homeSize(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_homeSize(999)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeFloatingMenuButton extends StatelessWidget {
  final AppPrimaryDestination currentDestination;
  final List<AppPrimaryDestination> destinations;

  const _HomeFloatingMenuButton({
    required this.currentDestination,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: MaterialLocalizations.of(context).showMenuTooltip,
      child: Semantics(
        button: true,
        label: MaterialLocalizations.of(context).showMenuTooltip,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              _showMenu(context);
            },
            child: Container(
              width: _homeSize(56),
              height: _homeSize(56),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _homeCardColor,
                border: Border.all(color: _homePanelBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: _homeSize(20),
                    offset: Offset(0, _homeSize(4)),
                  ),
                ],
              ),
              child: Icon(
                KeroseneIcons.menu,
                color: Colors.white,
                size: _homeSize(24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _homeSize(16),
              0,
              _homeSize(16),
              _homeSize(16),
            ),
            child: _HomeGlassPanel(
              borderRadius: BorderRadius.circular(_homeSize(18)),
              padding: EdgeInsets.symmetric(vertical: _homeSize(8)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final destination in destinations)
                    _HomeMenuDestinationTile(
                      destination: destination,
                      selected: destination == currentDestination,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HomeMenuDestinationTile extends StatelessWidget {
  final AppPrimaryDestination destination;
  final bool selected;

  const _HomeMenuDestinationTile({
    required this.destination,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final label = destination.label(context);
    final color = selected ? _homeAmberColor : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected
            ? null
            : () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                AppPrimaryNavigationBar.navigateTo(context, destination);
              },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _homeSize(18),
            vertical: _homeSize(14),
          ),
          child: Row(
            children: [
              Icon(destination.icon, color: color, size: _homeSize(22)),
              SizedBox(width: _homeSize(14)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontSize: _homeFontSize(15),
                        fontWeight:
                            selected ? FontWeight.w300 : FontWeight.w300,
                        letterSpacing: 0,
                      ),
                ),
              ),
              if (selected)
                Icon(
                  KeroseneIcons.check,
                  color: _homeAmberColor,
                  size: _homeSize(18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Transaction Popup Widget ────────────────────────────────────────────────
