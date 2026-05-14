import os
import re

lib_dir = '/home/omega/Kerosene/frontend/lib'

COLOR_MAPPINGS = {
    r'\bAppColors\.primary\b': r'Theme.of(context).colorScheme.primary',
    r'\bAppColors\.secondary\b': r'Theme.of(context).colorScheme.secondary',
    r'\bAppColors\.background\b': r'Theme.of(context).scaffoldBackgroundColor',
    r'\bAppColors\.surface\b': r'Theme.of(context).colorScheme.surface',
    r'\bAppColors\.error\b': r'Theme.of(context).colorScheme.error',
    r'\bAppColors\.white\b': r'Theme.of(context).colorScheme.onPrimary',
    r'\bAppColors\.black\b': r'Theme.of(context).colorScheme.onSurface',
    r'\bAppColors\.grey\b': r'Theme.of(context).colorScheme.onSurfaceVariant',
    r'\bAppColors\.darkGrey\b': r'Theme.of(context).colorScheme.surfaceContainerHighest',
    r'\bColors\.white\b': r'Theme.of(context).colorScheme.onPrimary',
    r'\bColors\.white70\b': r'Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)',
    r'\bColors\.white60\b': r'Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6)',
    r'\bColors\.white54\b': r'Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.54)',
    r'\bColors\.white38\b': r'Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.38)',
    r'\bColors\.white24\b': r'Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.24)',
    r'\bColors\.white12\b': r'Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.12)',
    r'\bColors\.black\b': r'Theme.of(context).colorScheme.onSurface',
    r'\bColors\.black87\b': r'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87)',
    r'\bColors\.black54\b': r'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)',
    r'\bColors\.black38\b': r'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)',
    r'\bColors\.black26\b': r'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.26)',
    r'\bColors\.black12\b': r'Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)',
    r'\bColors\.grey\b': r'Theme.of(context).colorScheme.onSurfaceVariant',
}

TYPOGRAPHY_MAPPINGS = {
    r'\bAppTypography\.h1\b': r'Theme.of(context).textTheme.displayLarge!',
    r'\bAppTypography\.h2\b': r'Theme.of(context).textTheme.titleLarge!',
    r'\bAppTypography\.h3\b': r'Theme.of(context).textTheme.titleMedium!',
    r'\bAppTypography\.bodyLarge\b': r'Theme.of(context).textTheme.bodyLarge!',
    r'\bAppTypography\.bodyMedium\b': r'Theme.of(context).textTheme.bodyMedium!',
    r'\bAppTypography\.bodySmall\b': r'Theme.of(context).textTheme.bodySmall!',
    r'\bAppTypography\.caption\b': r'Theme.of(context).textTheme.labelSmall!',
}

def process_file(filepath):
    # skip theme files where these define the system design mappings
    if filepath.endswith('app_theme.dart') or filepath.endswith('app_colors.dart') or filepath.endswith('app_typography.dart') or filepath.endswith('cyber_theme.dart'):
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Strip const before the replaced variables so we don't end up with `const Theme.of(context)`
    for key, val in {**COLOR_MAPPINGS, **TYPOGRAPHY_MAPPINGS}.items():
        # Match `const AppColors.primary` -> `Theme.of(...)`
        content = re.sub(r'const\s+' + key, val, content)
        # Match `AppColors.primary` -> `Theme.of(...)`
        content = re.sub(key, val, content)

    # Some variables might have been inside a list like `const [AppColors.primary]` which becomes `const [Theme.of(...)]` which is invalid.
    # We will fix these selectively during flutter analyze if they pop up, or remove const broadly.
    # A generic fix: `const [` to `[` if it contains `Theme.of(context)`
    # This is a bit too complex for a simple regex, we will rely on dart fix / manual intervention.

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

def main():
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
