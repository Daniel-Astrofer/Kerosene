import 'dart:io';

const _ignoredPathParts = <String>[
  '/lib/l10n/',
  '/features/landing/',
  '/features/web_admin/',
  '/test/',
  '/.dart_tool/',
];

const _allowedFiles = <String>{
  'lib/core/constants/app_copy.dart',
  'lib/core/utils/api_display_text.dart',
};

final _uiPattern = RegExp(
  r'(Text\(|title:|subtitle:|label:|hintText:|message:|tooltip:|localizedReason:|eyebrow:|showError\(|showSuccess\()',
);
final _quotedLiteral = RegExp(r'''(?:"[^"]+"|'[^']+')''');

void main() {
  final root = Directory.current;
  final libDir = Directory('${root.path}/lib');

  if (!libDir.existsSync()) {
    stderr.writeln('Run this script from the Flutter frontend directory.');
    exitCode = 2;
    return;
  }

  final findings = <String>[];

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final normalizedPath = entity.path.replaceAll('\\', '/');
    final relativePath = normalizedPath.replaceFirst('${root.path}/', '');
    final isPresentationLayer = relativePath.contains('/presentation/') ||
        relativePath.contains('/core/widgets/') ||
        relativePath.contains('/core/presentation/widgets/') ||
        relativePath.contains('/shared/widgets/') ||
        relativePath == 'lib/main.dart';

    if (_allowedFiles.contains(relativePath) ||
        _ignoredPathParts.any(normalizedPath.contains)) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final trimmed = line.trim();

      if (trimmed.startsWith('//') || trimmed.startsWith('///')) {
        continue;
      }

      if (line.contains('localeCopy(')) {
        findings.add('$relativePath:${index + 1}: remaining localeCopy usage');
        continue;
      }

      if (!_uiPattern.hasMatch(line)) {
        continue;
      }

      if (!isPresentationLayer && !line.contains('localizedReason:')) {
        continue;
      }

      if (!_quotedLiteral.hasMatch(line)) {
        continue;
      }

      if (_isAllowedNonCopyLiteral(trimmed)) {
        continue;
      }

      if (line.contains('AppCopy.') ||
          line.contains('LocalizedCopy(') ||
          line.contains('context.l10n') ||
          line.contains('.l10n.') ||
          line.contains('AppLocalizations.of(context)')) {
        continue;
      }

      findings.add(
        '$relativePath:${index + 1}: hardcoded visible string -> ${trimmed.replaceAll(RegExp(r'\s+'), ' ')}',
      );
    }
  }

  if (findings.isEmpty) {
    stdout.writeln('No hardcoded visible strings detected.');
    return;
  }

  stdout.writeln('Hardcoded visible strings detected:');
  for (final finding in findings) {
    stdout.writeln(' - $finding');
  }
  exitCode = 1;
}

bool _isAllowedNonCopyLiteral(String trimmed) {
  const allowedFragments = [
    "'TOTP'",
    "'SLIP-39'",
    "'PSBT'",
    "'BTC'",
    "'BITCOIN'",
    "'Black'",
    "'Bronze'",
    "'CARD HOLDER'",
    "'NFC'",
    "'QR'",
    "'S1'",
    "'S2'",
    "'S3'",
    "'000000'",
    "'VALID THRU'",
    "'White'",
    "'•'",
    '"•"',
    "'₿'",
    "'@\${",
    '"@\${',
    r"'$_",
    r'"$_',
    r"'$",
    r'"$',
  ];

  if (allowedFragments.any(trimmed.contains)) {
    return true;
  }

  return trimmed.contains("Text(isFilled ? text[index] : '•')") ||
      trimmed.contains('Text(index.toString()') ||
      trimmed.contains("Text('S1'") ||
      trimmed.contains("Text('S2'") ||
      trimmed.contains("Text('S3'");
}
