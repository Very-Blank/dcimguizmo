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
            i += 1 # skip the line with ]]
        else:
            result.append(line)
            i += 1
 
    return ''.join(result)


content = open(sys.argv[1]).read()

# Replace the namespace macro and any explicit mentions with 'ImGui'
# This tricks dear_bindings into applying its flattening logic
content = content.replace('IMGUIZMO_NAMESPACE', 'ImGui')
content = content.replace('ImGuizmo::', 'ImGui::')
# Some versions of ImGuizmo.h might use namespace ImGuizmo directly
content = re.sub(r'namespace\s+ImGuizmo', 'namespace ImGui', content)

# Fix C++-style enum access
content = re.sub(r'(\w+)::(\w+)', r'\2', content)

# Convert plain enums to typedef enums to help dear_bindings
def typedef_enum(match):
    enum_name = match.group(1)
    enum_body = match.group(2)
    return f"typedef enum {enum_name}\n    {enum_body} {enum_name};"

content = re.sub(r'enum\s+(\w+)\s*(\{.*?\});', typedef_enum, content, flags=re.DOTALL)

# Remove u suffix from numbers
content = re.sub(r'(\d+)u', r'\1', content)

# Remove operator overloads which are C++ only and might confuse the parser
content = re.sub(r'inline\s+OPERATION\s+operator\|.*?\n\s+\{\n.*?\n\s+\}', '', content, flags=re.DOTALL)

content = remove_deprecated(content)

open(sys.argv[2], 'w').write(content)
