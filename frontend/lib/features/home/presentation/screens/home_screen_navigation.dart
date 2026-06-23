// ignore_for_file: use_key_in_widget_constructors

import 'home_screen_dependencies.dart';

class HomeBottomNavigationOverlay extends StatelessWidget {
  final AppPrimaryDestination currentDestination;

  const HomeBottomNavigationOverlay({required this.currentDestination});

  @override
  Widget build(BuildContext context) {
    return AppPrimaryNavigationBar.overlay(
      currentDestination: currentDestination,
    );
  }
}
