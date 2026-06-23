import 'dart:io';

const _baselinePath = 'tool/frontend_architecture_baseline.txt';
const _largeFileLineLimit = 1000;

const _skipDirectoryNames = <String>{
  '.dart_tool',
  'build',
};

const _legacyFinancialRoutes = <String>{
  '/card',
  '/bitcoin/advanced',
  '/history',
};

void main(List<String> args) {
  final root = Directory.current;
  final lib = Directory('${root.path}/lib');
  if (!lib.existsSync()) {
    _die(
        'Run this guard from the frontend directory. Expected ./lib to exist.');
  }

  final violations = <_Violation>[];
  final dartFiles = _dartFiles(lib).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  _checkForbiddenFeatureArchiveDirs(violations);

  for (final file in dartFiles) {
    final relativePath = _relative(file.path, root.path);
    final text = file.readAsStringSync();
    final lines = text.split('\n');

    _checkImports(violations, relativePath, lines);
    _checkPartFiles(violations, relativePath, lines);
    _checkLegacyRoutes(violations, relativePath, lines, text);
    _checkLargeFile(violations, relativePath, lines, text);
  }

  final signatures = violations.map((violation) => violation.signature).toSet();

  if (args.contains('--write-baseline')) {
    _writeBaseline(signatures);
    stdout.writeln('Frontend architecture baseline written to $_baselinePath.');
    stdout.writeln('Baseline entries: ${signatures.length}');
    return;
  }

  final baseline = _readBaseline();
  final unbaselined = violations
      .where((violation) => !baseline.contains(violation.signature))
      .toList();
  final resolvedBaseline = baseline.difference(signatures).toList()..sort();

  if (unbaselined.isNotEmpty) {
    stderr.writeln('Frontend architecture guard failed.');
    stderr.writeln('New or unapproved violations:');
    for (final violation in unbaselined) {
      stderr.writeln(
          '- ${violation.rule}: ${violation.path} — ${violation.detail}');
    }
    stderr.writeln('');
    stderr.writeln(
        'Fix the violation or, for an intentional temporary exception, document it and update $_baselinePath explicitly.');
    exit(1);
  }

  stdout.writeln('Frontend architecture guard passed.');
  stdout.writeln('Known baseline violations: ${violations.length}');
  if (resolvedBaseline.isNotEmpty) {
    stdout.writeln(
        'Resolved baseline entries that can be removed: ${resolvedBaseline.length}');
  }
}

void _checkForbiddenFeatureArchiveDirs(List<_Violation> violations) {
  for (final path in const ['lib/features/_legacy', 'lib/features/_roadmap']) {
    if (Directory(path).existsSync()) {
      violations.add(_Violation(
        'forbidden_feature_archive_dir',
        path,
        'Move archive/roadmap material out of lib/features.',
      ));
    }
  }
}

void _checkImports(
    List<_Violation> violations, String relativePath, List<String> lines) {
  final imports = _imports(lines);
  final isCore = relativePath.startsWith('lib/core/');
  final isDesignSystem = relativePath.startsWith('lib/design_system/');
  final isPresentation = relativePath.contains('/presentation/');

  for (final import in imports) {
    final target = _resolvedImportPath(relativePath, import.uri);
    final importsFeature =
        import.uri.startsWith('package:kerosene/features/') ||
            (target != null && target.startsWith('lib/features/'));
    final importsData = import.uri.contains('/data/') ||
        (target != null && target.contains('/data/'));

    if (isCore && importsFeature) {
      violations.add(_Violation(
        'core_imports_features',
        relativePath,
        'line ${import.line}: ${import.uri}',
      ));
    }

    if (isDesignSystem && importsFeature) {
      violations.add(_Violation(
        'design_system_imports_features',
        relativePath,
        'line ${import.line}: ${import.uri}',
      ));
    }

    if (isPresentation && importsData && !_hasArchitectureException(lines)) {
      violations.add(_Violation(
        'presentation_imports_data',
        relativePath,
        'line ${import.line}: ${import.uri}',
      ));
    }
  }
}

void _checkPartFiles(
    List<_Violation> violations, String relativePath, List<String> lines) {
  if (relativePath.contains('/generated/') || relativePath.contains('/l10n/')) {
    return;
  }

  final partPattern = RegExp(r'''^\s*part\s+[\'"]''');
  final partOfPattern = RegExp(r'^\s*part\s+of\b');
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (partPattern.hasMatch(line) || partOfPattern.hasMatch(line)) {
      violations.add(_Violation(
        'part_usage_outside_generated_or_l10n',
        relativePath,
        'line ${index + 1}: ${line.trim()}',
      ));
    }
  }
}

void _checkLegacyRoutes(
  List<_Violation> violations,
  String relativePath,
  List<String> lines,
  String text,
) {
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    for (final route in _legacyFinancialRoutes) {
      if (!line.contains("'$route'") && !line.contains('"$route"')) {
        continue;
      }

      final documentedRedirect =
          text.contains('legacy-route-redirect: $route') ||
              line.contains('legacy-route-redirect');
      if (!documentedRedirect) {
        violations.add(_Violation(
          'legacy_financial_route_without_redirect_doc',
          relativePath,
          'line ${index + 1}: $route',
        ));
      }
    }
  }
}

void _checkLargeFile(
  List<_Violation> violations,
  String relativePath,
  List<String> lines,
  String text,
) {
  if (lines.length <= _largeFileLineLimit) return;
  if (text.contains('architecture-allow-large-file')) return;

  violations.add(_Violation(
    'large_file_without_justification',
    relativePath,
    '${lines.length} lines; limit is $_largeFileLineLimit.',
  ));
}

Iterable<File> _dartFiles(Directory dir) sync* {
  for (final entity in dir.listSync(recursive: false, followLinks: false)) {
    final name = _basename(entity.path);
    if (entity is Directory) {
      if (_skipDirectoryNames.contains(name)) continue;
      yield* _dartFiles(entity);
    } else if (entity is File && entity.path.endsWith('.dart')) {
      yield entity;
    }
  }
}

List<_Import> _imports(List<String> lines) {
  final imports = <_Import>[];
  final pattern = RegExp(r'''^\s*import\s+[\'"]([^\'"]+)[\'"]''');
  for (var index = 0; index < lines.length; index++) {
    final match = pattern.firstMatch(lines[index]);
    if (match == null) continue;
    imports.add(_Import(index + 1, match.group(1)!));
  }
  return imports;
}

String? _resolvedImportPath(String importerRelativePath, String uri) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:kerosene/')) {
    return 'lib/${uri.substring('package:kerosene/'.length)}';
  }
  if (uri.startsWith('package:')) return null;

  final importerDir = importerRelativePath.split('/')..removeLast();
  final uriParts = uri.split('/');
  return _normalizePath([...importerDir, ...uriParts]);
}

String _normalizePath(List<String> parts) {
  final normalized = <String>[];
  for (final part in parts) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (normalized.isNotEmpty) normalized.removeLast();
      continue;
    }
    normalized.add(part);
  }
  return normalized.join('/');
}

String _relative(String path, String rootPath) {
  final normalizedRoot = rootPath.endsWith('/') ? rootPath : '$rootPath/';
  return path.startsWith(normalizedRoot)
      ? path.substring(normalizedRoot.length)
      : path;
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final slash = normalized.lastIndexOf('/');
  return slash == -1 ? normalized : normalized.substring(slash + 1);
}

bool _hasArchitectureException(List<String> lines) {
  return lines.any((line) => line.contains('architecture-exception'));
}

Set<String> _readBaseline() {
  final file = File(_baselinePath);
  if (!file.existsSync()) return <String>{};
  return file
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

void _writeBaseline(Set<String> signatures) {
  final sorted = signatures.toList()..sort();
  final file = File(_baselinePath);
  file.writeAsStringSync([
    '# Current frontend architecture baseline.',
    '# Entries are temporary and should be removed as phases 3-9 clean the codebase.',
    '# Format: rule|path|detail',
    ...sorted,
    '',
  ].join('\n'));
}

void _die(String message) {
  stderr.writeln(message);
  exit(2);
}

class _Import {
  final int line;
  final String uri;

  const _Import(this.line, this.uri);
}

class _Violation {
  final String rule;
  final String path;
  final String detail;

  const _Violation(this.rule, this.path, this.detail);

  String get signature => '$rule|$path|$detail';
}
