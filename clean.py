import sys, re

# 1000 % AI garbage (but now fixed).
def remove_deprecated(source: str) -> str:
    # Completely remove function declarations marked with [[deprecated]]
    # This matches [[deprecated("...")]] followed by IMGUI_API and the function declaration up to the semicolon.
    source = re.sub(r'\[\[deprecated.*?\]\]\s*(IMGUI_API\s+[^;]*;)', '', source, flags=re.DOTALL)
    return source


content = open(sys.argv[1]).read()

# Replace the namespace macro and any explicit mentions with 'ImGui'
# This tricks dear_bindings into applying its flattening logic
content = content.replace('IMGUIZMO_NAMESPACE', 'ImGui')
content = content.replace('ImGuizmo::', 'ImGui::')
# Some versions of ImGuizmo.h might use namespace ImGuizmo directly
content = re.sub(r'namespace\s+ImGuizmo', 'namespace ImGui', content)

# Fix C++-style enum access
content = re.sub(r'(\w+)::(\w+)', r'\2', content)

# Remove operator overloads which are C++ only and might confuse the parser
content = re.sub(r'inline\s+OPERATION\s+operator\|.*?\n\s+\{\n.*?\n\s+\}', '', content, flags=re.DOTALL)

# Extract enums and move them to global scope with ImGuizmo_ prefix
def extract_and_move_enums(content):
    enums_to_move = ['OPERATION', 'MODE', 'MOVETYPE', 'COLOR']
    extracted_enums = []
    
    for enum_name in enums_to_move:
        # Match the enum definition: enum NAME { ... };
        pattern = r'(enum\s+' + enum_name + r'\s*\{.*?\};)'
        match = re.search(pattern, content, flags=re.DOTALL)
        if match:
            enum_def = match.group(1)
            # Remove from content
            content = content.replace(enum_def, '')
            
            # Format as global ImGui-style enum with ImGuizmo_ prefix and guard
            enum_body = re.search(r'\{.*?\}', enum_def, flags=re.DOTALL).group(0)
            global_enum = f"""#ifndef ImGuizmo_{enum_name}_DEFINED
enum ImGuizmo_{enum_name}_\n{enum_body};
typedef int ImGuizmo_{enum_name};
#endif"""
            extracted_enums.append(global_enum)
            
    # Insert extracted enums right before "namespace ImGui"
    insert_pos = content.find('namespace ImGui')
    if insert_pos != -1:
        content = content[:insert_pos] + '\n\n' + '\n\n'.join(extracted_enums) + '\n\n' + content[insert_pos:]
        
    # Replace all other usages of these enums with their global names
    for enum_name in enums_to_move:
        content = re.sub(r'\b' + enum_name + r'\b', f'ImGuizmo_{enum_name}', content)
        
    return content

# Extract Style struct and move to global scope
def extract_and_move_style(content):
    # Match struct Style { ... };
    pattern = r'(struct\s+Style\s*\{.*?\};)'
    match = re.search(pattern, content, flags=re.DOTALL)
    if match:
        struct_def = match.group(1)
        # Remove from content
        content = content.replace(struct_def, '')
        
        # Rename inside the definition
        struct_def = struct_def.replace('struct Style', 'struct ImGuizmo_Style')
        struct_def = struct_def.replace('Style();', 'ImGuizmo_Style();')
        
        # Wrap in guard and add typedef
        struct_def = f"""#ifndef ImGuizmo_Style_DEFINED
{struct_def}
typedef struct ImGuizmo_Style_t ImGuizmo_Style;
#endif"""
        
        # Insert before "namespace ImGui"
        insert_pos = content.find('namespace ImGui')
        if insert_pos != -1:
            content = content[:insert_pos] + '\n\n' + struct_def + '\n\n' + content[insert_pos:]
            
        # Replace all other usages
        content = re.sub(r'\bStyle\b', 'ImGuizmo_Style', content)
        
    return content

content = extract_and_move_enums(content)
content = extract_and_move_style(content)

# Remove u suffix from numbers
content = re.sub(r'(\d+)u', r'\1', content)

content = remove_deprecated(content)

open(sys.argv[2], 'w').write(content)
