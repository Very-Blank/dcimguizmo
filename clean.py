import sys, re

# 1000 % AI garbage.
def remove_deprecated(source: str) -> str:
    lines = source.splitlines(keepends=True)
    result = []
    i = 0
 
    while i < len(lines):
        line = lines[i]
        if '[[deprecated' in line:
            block = line
            while ']]' not in block and i + 1 < len(lines):
                i += 1
                block += lines[i]
            i += 2
        else:
            result.append(line)
            i += 1
 
    return ''.join(result)


content = open(sys.argv[1]).read()
content = re.sub(r'(\d+)u', r'\1', content)
content = remove_deprecated(content)

open(sys.argv[2], 'w').write(content)
