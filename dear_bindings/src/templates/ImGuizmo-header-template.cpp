#include "imgui.h"
#include "ImGuizmo.h"

#include <stdio.h>

typedef ImGuizmo::OPERATION OPERATION;
typedef ImGuizmo::MODE MODE;
typedef ImGuizmo::MOVETYPE MOVETYPE;
typedef ImGuizmo::COLOR COLOR;
typedef ImGuizmo::Style Style;

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
