#include "imgui.h"
#include "ImGuizmo.h"

#include <stdio.h>

typedef ImGuizmo::OPERATION OPERATION;
typedef ImGuizmo::MODE MODE;
typedef ImGuizmo::MOVETYPE MOVETYPE;
typedef ImGuizmo::COLOR COLOR;
typedef ImGuizmo::Style Style;

// Define the typedefs in the global namespace and guard them
// so they are available globally for return types in cimguizmo.cpp,
// and the duplicate definitions in cimguizmo.h are skipped.
typedef ::OPERATION ImGuizmo_OPERATION;
#define ImGuizmo_OPERATION_DEFINED

typedef ::MODE ImGuizmo_MODE;
#define ImGuizmo_MODE_DEFINED

typedef ::MOVETYPE ImGuizmo_MOVETYPE;
#define ImGuizmo_MOVETYPE_DEFINED

typedef ::COLOR ImGuizmo_COLOR;
#define ImGuizmo_COLOR_DEFINED

typedef ::Style ImGuizmo_Style;
#define ImGuizmo_Style_DEFINED

// Wrap this in a namespace to keep it separate from the C++ API.
#define DEAR_BINDINGS_INTERNAL_GLUE_CODE
namespace cimgui
{
    typedef ::OPERATION OPERATION;
    typedef ::MODE MODE;
    typedef ::MOVETYPE MOVETYPE;
    typedef ::COLOR COLOR;
    typedef ::Style Style;

    #include "%OUTPUT_HEADER_NAME%"
}
#undef DEAR_BINDINGS_INTERNAL_GLUE_CODE
