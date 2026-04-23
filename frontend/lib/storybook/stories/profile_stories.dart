// Kerosene Storybook — Profile & Settings Screen Stories
// Contains profile, personal data, notifications, security, support, and global settings.
import 'package:storybook_flutter/storybook_flutter.dart';

import 'package:teste/features/profile/presentation/screens/profile_screen.dart';
import 'package:teste/features/profile/presentation/screens/personal_data_screen.dart';
import 'package:teste/features/profile/presentation/screens/notification_settings_screen.dart';
import 'package:teste/features/profile/presentation/screens/security_settings_screen.dart';
import 'package:teste/features/profile/presentation/screens/support_screen.dart';
import 'package:teste/features/settings/presentation/screens/settings_screen.dart';

/// Returns all profile and settings-related stories.
List<Story> profileStories() {
  return [
    Story(
      name: 'Profile/Main Profile',
      description:
          'User profile overview with avatar, username, and quick actions.',
      builder: (context) => const ProfileScreen(),
    ),
    Story(
      name: 'Profile/Personal Data',
      description: 'Edit personal information (name, email, phone).',
      builder: (context) => const PersonalDataScreen(),
    ),
    Story(
      name: 'Profile/Notification Settings',
      description: 'Configure push/email notification preferences.',
      builder: (context) => const NotificationSettingsScreen(),
    ),
    Story(
      name: 'Profile/Security Settings',
      description: 'Manage 2FA, passkeys, biometric locks, and PIN.',
      builder: (context) => const SecuritySettingsScreen(),
    ),
    Story(
      name: 'Profile/Support & Help',
      description: 'Contact support, FAQ, and troubleshooting.',
      builder: (context) => const SupportScreen(),
    ),
    Story(
      name: 'Settings/Global Settings',
      description: 'App-wide settings: language, currency, Tor, theme.',
      builder: (context) => const SettingsScreen(),
    ),
  ];
}
