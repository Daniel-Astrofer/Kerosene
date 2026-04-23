import re

REVERSE_MAPPING = {
    r'Theme\.of\(context\)\.colorScheme\.primary': 'AppColors.primary',
    r'Theme\.of\(context\)\.colorScheme\.secondary': 'AppColors.secondary',
    r'Theme\.of\(context\)\.scaffoldBackgroundColor': 'AppColors.background',
    r'Theme\.of\(context\)\.colorScheme\.surface': 'AppColors.surface',
    r'Theme\.of\(context\)\.colorScheme\.error': 'AppColors.error',
    r'Theme\.of\(context\)\.colorScheme\.onPrimary\.withValues\(alpha:\s*0\.7\)': 'Colors.white70',
    r'Theme\.of\(context\)\.colorScheme\.onPrimary\.withValues\(alpha:\s*0\.6\)': 'Colors.white60',
    r'Theme\.of\(context\)\.colorScheme\.onPrimary\.withValues\(alpha:\s*0\.54\)': 'Colors.white54',
    r'Theme\.of\(context\)\.colorScheme\.onPrimary\.withValues\(alpha:\s*0\.38\)': 'Colors.white38',
    r'Theme\.of\(context\)\.colorScheme\.onPrimary\.withValues\(alpha:\s*0\.24\)': 'Colors.white24',
    r'Theme\.of\(context\)\.colorScheme\.onPrimary\.withValues\(alpha:\s*0\.12\)': 'Colors.white12',
    r'Theme\.of\(context\)\.colorScheme\.onPrimary': 'Colors.white',
    r'Theme\.of\(context\)\.colorScheme\.onSurface\.withValues\(alpha:\s*0\.87\)': 'Colors.black87',
    r'Theme\.of\(context\)\.colorScheme\.onSurface\.withValues\(alpha:\s*0\.54\)': 'Colors.black54',
    r'Theme\.of\(context\)\.colorScheme\.onSurface\.withValues\(alpha:\s*0\.38\)': 'Colors.black38',
    r'Theme\.of\(context\)\.colorScheme\.onSurface\.withValues\(alpha:\s*0\.26\)': 'Colors.black26',
    r'Theme\.of\(context\)\.colorScheme\.onSurface\.withValues\(alpha:\s*0\.12\)': 'Colors.black12',
    r'Theme\.of\(context\)\.colorScheme\.onSurface': 'Colors.black',
    r'Theme\.of\(context\)\.colorScheme\.onSurfaceVariant': 'AppColors.grey',
    r'Theme\.of\(context\)\.colorScheme\.surfaceContainerHighest': 'AppColors.darkGrey',

    r'Theme\.of\(context\)\.textTheme\.displayLarge!': 'AppTypography.h1',
    r'Theme\.of\(context\)\.textTheme\.titleLarge!': 'AppTypography.h2',
    r'Theme\.of\(context\)\.textTheme\.titleMedium!': 'AppTypography.h3',
    r'Theme\.of\(context\)\.textTheme\.bodyLarge!': 'AppTypography.bodyLarge',
    r'Theme\.of\(context\)\.textTheme\.bodyMedium!': 'AppTypography.bodyMedium',
    r'Theme\.of\(context\)\.textTheme\.bodySmall!': 'AppTypography.bodySmall',
    r'Theme\.of\(context\)\.textTheme\.labelSmall!': 'AppTypography.caption',
}

def revert_line(filepath, line_number):
    try:
        with open(filepath, 'r') as f:
            lines = f.read().split('\n')

        if 0 < line_number <= len(lines):
            line_str = lines[line_number - 1]
            for pat, repl in REVERSE_MAPPING.items():
                line_str = re.sub(pat, repl, line_str)
            lines[line_number - 1] = line_str
            with open(filepath, 'w') as f:
                f.write('\n'.join(lines))
    except Exception as e:
        print(f"Failed to process {filepath}:{line_number}")

def remove_const_near(filepath, line_number):
    try:
        with open(filepath, 'r') as f:
            lines = f.read().split('\n')

        for i in range(line_number - 1, max(-1, line_number - 10), -1):
            if 'const ' in lines[i]:
                new_line = re.sub(r'\bconst\s+', '', lines[i], count=1)
                if new_line != lines[i]:
                    lines[i] = new_line
                    with open(filepath, 'w') as f:
                        f.write('\n'.join(lines))
                    return
    except Exception as e:
        print(f"Failed to remove const in {filepath}:{line_number}")

def main():
    print("Reverting context errors based on analyze2.log...")
    with open('analyze2.log', 'r') as f:
        log_lines = f.readlines()

    for line in log_lines:
        if ' • ' not in line: continue
        parts = line.split(' • ')
        if len(parts) >= 3:
            msg = parts[1]
            code = parts[3].strip() if len(parts) > 3 else ""
            location = parts[2].split(':')
            if len(location) == 3:
                filepath, line_num, col = location[0].strip(), int(location[1]), int(location[2])

                # Context errors
                if ("Undefined name 'context'" in msg or
                    "instance member" in msg or
                    "initializer" in msg or
                    "default_value" in code):
                    revert_line(filepath, line_num)

                # Const errors
                if ("constant" in msg.lower() or "const_" in code):
                    remove_const_near(filepath, line_num)

if __name__ == '__main__':
    main()
