#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path('lib')
SKIP_PARTS = {
    '_legacy',
    '_roadmap',
    '.dart_tool',
    'build',
}

ALLOWED_EXACT = {
    Path('lib/core/theme/app_colors.dart'),
    Path('lib/core/theme/app_theme.dart'),
    Path('lib/core/theme/app_typography.dart'),
    Path('lib/core/theme/monochrome_theme.dart'),
    Path('lib/core/theme/design_system_template.dart'),
    Path('lib/core/motion/app_motion.dart'),
    Path('lib/design_system/icons/kerosene_icons.dart'),
    Path('lib/design_system/animation/kerosene_lottie.dart'),
    Path('lib/design_system/animation/kerosene_rive.dart'),
    Path('lib/dev_menu.dart'),
    Path('lib/storybook/stories/wallet_flow_stories.dart'),
    Path('lib/core/widgets/animated_number_display.dart'),
}

DIRECT_MATERIAL_ICON = re.compile(r'(?<!Kerosene)Icons\.')
RAW_FONT_FAMILY_LITERAL = re.compile(r"fontFamily\s*:\s*['\"]")

CHECKS = [
    ('direct lucide package', lambda text: 'package:lucide_icons' in text),
    ('direct LucideIcons usage', lambda text: 'LucideIcons.' in text),
    ('Cyber naming/visual language', lambda text: 'Cyber' in text),
    ('direct color literal', lambda text: 'Color(0x' in text),
    ('direct GoogleFonts call', lambda text: 'GoogleFonts.' in text),
    ('direct google_fonts package', lambda text: 'package:google_fonts/google_fonts.dart' in text),
    ('raw fontFamily literal', lambda text: bool(RAW_FONT_FAMILY_LITERAL.search(text))),
    ('direct Material Icons usage', lambda text: bool(DIRECT_MATERIAL_ICON.search(text))),
    ('direct lottie package', lambda text: 'package:lottie' in text),
    ('direct lottie widget usage', lambda text: 'Lottie.' in text),
    ('direct rive package', lambda text: 'package:rive' in text),
    ('direct runtime animation widget usage', lambda text: 'RiveAnimation.' in text or 'RiveWidget' in text),
]

violations: list[str] = []

for path in ROOT.rglob('*.dart'):
    if any(part in SKIP_PARTS for part in path.parts):
        continue
    text = path.read_text(errors='ignore')
    for label, predicate in CHECKS:
        if not predicate(text):
            continue
        if path in ALLOWED_EXACT:
            continue
        violations.append(f'{path}: {label}')

if violations:
    print('\n'.join(sorted(set(violations))), file=sys.stderr)
    print('\nFrontend cleanup guard failed.', file=sys.stderr)
    print('Use Kerosene design-system wrappers/tokens instead of raw icons, colors, cyber naming, or direct font packages.', file=sys.stderr)
    sys.exit(1)

print('Frontend cleanup guard passed.')
PY
