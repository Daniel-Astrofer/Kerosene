import collections
import re

def main():
    with open('analyze.log', 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    error_types = collections.Counter()
    for line in lines:
        if ' • ' in line:
            # Format is usually "  error • Message • file:line:col • code"
            parts = line.split(' • ')
            if len(parts) >= 2:
                msg = parts[1]
                # simplify message to group them
                msg = re.sub(r"'.*?'", "'...'", msg)
                error_types[msg] += 1
                
    for msg, count in error_types.most_common():
        print(f"{count}: {msg}")

if __name__ == '__main__':
    main()
