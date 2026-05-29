import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:storybook_flutter/storybook_flutter.dart';
import 'package:kerosene/features/web_admin/navigation/admin_content_router.dart';
import 'package:kerosene/features/web_admin/navigation/admin_routes.dart';
import 'package:kerosene/features/web_admin/screens/login/admin_login_screen.dart';
import 'package:kerosene/features/web_admin/shell/admin_shell.dart';
import 'package:kerosene/features/web_admin/theme/admin_theme.dart';

List<Story> adminStories() {
  return [
    Story(
      name: 'Admin/Login',
      builder: (_) => const AdminLoginScreen(),
    ),
    for (final route in AdminRoute.values)
      Story(
        name: 'Admin/${route.label}',
        builder: (_) => _AdminRouteStory(route: route),
      ),
  ];
}

class _AdminRouteStory extends StatelessWidget {
  final AdminRoute route;

  const _AdminRouteStory({required this.route});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        adminRouteProvider.overrideWith(
          () => _StoryAdminRouteNotifier(route),
        ),
      ],
      child: Theme(
        data: AdminTheme.themeData,
        child: const AdminShell(child: AdminContentRouter()),
      ),
    );
  }
}

class _StoryAdminRouteNotifier extends AdminRouteNotifier {
  final AdminRoute initialRoute;

  _StoryAdminRouteNotifier(this.initialRoute);

  @override
  AdminRoute build() => initialRoute;
}
