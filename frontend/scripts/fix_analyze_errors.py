import os
import subprocess
import re

def revert_line(filepath, line_number):
    try:
        orig_content = subprocess.check_output(['git', 'show', f'HEAD:{filepath}']).decode('utf-8')
        orig_lines = orig_content.split('\n')
        
        with open(filepath, 'r') as f:
            lines = f.read().split('\n')
            
        if 0 < line_number <= len(lines) and 0 < line_number <= len(orig_lines):
            lines[line_number - 1] = orig_lines[line_number - 1]
            with open(filepath, 'w') as f:
                f.write('\n'.join(lines))
    except Exception as e:
        print(f"Failed to revert {filepath}:{line_number}")

def remove_const_near(filepath, line_number):
    try:
        with open(filepath, 'r') as f:
            lines = f.read().split('\n')
            
        for i in range(line_number - 1, max(-1, line_number - 10), -1):
            if 'const ' in lines[i]:
                # replace only the first occurrence on this line
                new_line = re.sub(r'\bconst\s+', '', lines[i], count=1)
                if new_line != lines[i]:
                    lines[i] = new_line
                    with open(filepath, 'w') as f:
                        f.write('\n'.join(lines))
                    return
    except Exception as e:
        print(f"Failed to remove const in {filepath}:{line_number}")

def main():
    print("Fixing errors based on analyze.log...")
    with open('analyze.log', 'r') as f:
        log_lines = f.readlines()
        
    # We might have multiple errors per file, we should process them.
    # To avoid offset issues, we can revert lines first, then remove consts.
    
    for line in log_lines:
        if ' • ' not in line: continue
        parts = line.split(' • ')
        if len(parts) >= 3:
            msg = parts[1]
            code = parts[3].strip() if len(parts) > 3 else ""
            location = parts[2].split(':')
            if len(location) == 3:
                filepath, line_num, col = location[0].strip(), int(location[1]), int(location[2])
                
                if "Undefined name 'context'" in msg or "instance member" in msg or "initializer" in msg or "default_value" in code:
                    revert_line(filepath, line_num)
                    
                if "constant" in msg.lower() or "const_" in code:
                    remove_const_near(filepath, line_num)

if __name__ == '__main__':
    main()
