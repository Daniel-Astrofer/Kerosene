#!/usr/bin/env python3
from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

ROOT = Path('lib')

SKIP_PARTS = {
    '_legacy',
    '_roadmap',
    '.dart_tool',
    'build',
}

PRODUCT_SKIP_PARTS = {
    'storybook',
}

ALLOWED_HARD_FILES = {
    Path('lib/core/theme/app_colors.dart'),
    Path('lib/core/theme/app_theme.dart'),
    Path('lib/core/theme/app_typography.dart'),
    Path('lib/core/theme/monochrome_theme.dart'),
    Path('lib/core/theme/design_system_template.dart'),
    Path('lib/core/motion/app_motion.dart'),
    Path('lib/design_system/icons/kerosene_icons.dart'),
    Path('lib/design_system/animation/kerosene_lottie.dart'),
    Path('lib/design_system/animation/kerosene_rive.dart'),
}

TEXT_ALLOWED_FILES = {
    Path('lib/dev_menu.dart'),
    Path('lib/core/widgets/animated_number_display.dart'),
}


OPERATIONAL_DURATION_FILES = {
    Path('lib/core/constants/app_constants.dart'),
    Path('lib/core/network/api_client.dart'),
    Path('lib/core/providers/network_status_provider.dart'),
    Path('lib/core/services/balance_websocket_service.dart'),
    Path('lib/core/services/price_websocket_service.dart'),
    Path('lib/core/services/tor_service.dart'),
    Path('lib/features/auth/controller/auth_controller.dart'),
    Path('lib/features/security/presentation/screens/sovereignty_status_screen.dart'),
    Path('lib/features/security/presentation/widgets/app_entry_pin_gate.dart'),
    Path('lib/features/web_admin/screens/login/admin_login_screen.dart'),
}

MOTION_ALLOWED_HINTS = (
    'timeout',
    'debounce',
    'poll',
    'retry',
    'cache',
    'websocket',
    'socket',
    'network',
)

DIRECT_MATERIAL_ICON = re.compile(r'(?<!Kerosene)Icons\.')
RAW_FONT_FAMILY_LITERAL = re.compile(r"fontFamily\s*:\s*['\"]")
RAW_TEXT_LITERAL = re.compile(r"\bText\s*\(\s*(['\"])(.*?)\1", re.S)
DURATION_LITERAL = re.compile(r'Duration\s*\(\s*(milliseconds|seconds)\s*:')

@dataclass(frozen=True)
class Rule:
    name: str
    kind: str
    predicate: object
    allowed_files: frozenset[Path] = frozenset()


def has_direct_material_icon(text: str) -> bool:
    return bool(DIRECT_MATERIAL_ICON.search(text))


def has_raw_font_family(text: str) -> bool:
    return bool(RAW_FONT_FAMILY_LITERAL.search(text))


def has_raw_text(text: str) -> bool:
    for match in RAW_TEXT_LITERAL.finditer(text):
        literal = match.group(2).strip()
        if not literal:
            continue
        if '$' in literal:
            continue
        if literal.startswith('/'):
            continue
        if len(literal) == 1 and literal.isupper():
            continue
        if any(ch.isalpha() for ch in literal):
            return True
    return False


def has_duration_literal(text: str) -> bool:
    return bool(DURATION_LITERAL.search(text))


RULES = [
    Rule('direct_lucide_package', 'hard-zero', lambda t: 'package:lucide_icons' in t, frozenset(ALLOWED_HARD_FILES)),
    Rule('direct_lucide_icons', 'hard-zero', lambda t: 'LucideIcons.' in t, frozenset(ALLOWED_HARD_FILES)),
    Rule('direct_material_icons', 'hard-zero', has_direct_material_icon, frozenset(ALLOWED_HARD_FILES | TEXT_ALLOWED_FILES)),
    Rule('cyber_language', 'hard-zero', lambda t: 'Cyber' in t, frozenset(ALLOWED_HARD_FILES)),
    Rule('raw_color_literal', 'hard-zero', lambda t: 'Color(0x' in t, frozenset(ALLOWED_HARD_FILES)),
    Rule('google_fonts_direct', 'hard-zero', lambda t: 'GoogleFonts.' in t or 'package:google_fonts/google_fonts.dart' in t, frozenset(ALLOWED_HARD_FILES)),
    Rule('raw_font_family_literal', 'hard-zero', has_raw_font_family, frozenset(ALLOWED_HARD_FILES)),
    Rule('direct_lottie_runtime', 'hard-zero', lambda t: 'package:lottie' in t or 'Lottie.' in t, frozenset(ALLOWED_HARD_FILES)),
    Rule('direct_rive_runtime', 'hard-zero', lambda t: 'package:rive' in t or 'RiveAnimation.' in t or 'RiveWidget' in t, frozenset(ALLOWED_HARD_FILES)),
    Rule('raw_text_literal', 'advisory', has_raw_text, frozenset(TEXT_ALLOWED_FILES)),
    Rule(
        'duration_literal',
        'advisory',
        has_duration_literal,
        frozenset(ALLOWED_HARD_FILES | OPERATIONAL_DURATION_FILES),
    ),
    Rule('curves_direct', 'advisory', lambda t: 'Curves.' in t, frozenset({Path('lib/core/motion/app_motion.dart')})),
]


def should_skip(path: Path) -> bool:
    parts = set(path.parts)
    return bool(parts & SKIP_PARTS)


def is_product_path(path: Path) -> bool:
    return not bool(set(path.parts) & PRODUCT_SKIP_PARTS)


def line_numbers(text: str, needle: str) -> list[int]:
    return [index for index, line in enumerate(text.splitlines(), start=1) if needle in line]


def main() -> int:
    hard: list[tuple[str, Path]] = []
    advisory: list[tuple[str, Path]] = []

    for path in sorted(ROOT.rglob('*.dart')):
        if should_skip(path):
            continue
        try:
            text = path.read_text(errors='ignore')
        except OSError:
            continue

        for rule in RULES:
            if path in rule.allowed_files:
                continue
            if not is_product_path(path) and rule.kind == 'advisory':
                continue
            if rule.predicate(text):
                target = hard if rule.kind == 'hard-zero' else advisory
                target.append((rule.name, path))

    print('# Frontend alignment audit')
    print()
    print(f'hard_zero_findings: {len(hard)}')
    for name, path in hard:
        print(f'  - {path}: {name}')

    print()
    print(f'advisory_findings: {len(advisory)}')
    for name, path in advisory:
        print(f'  - {path}: {name}')

    if hard:
        print()
        print('status: FAIL')
        print('reason: hard-zero design-system rule violated')
        return 1

    print()
    print('status: PASS')
    print('note: advisory findings are review items, not automatic failures.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
