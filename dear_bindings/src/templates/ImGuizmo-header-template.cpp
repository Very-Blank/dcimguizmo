#include "imgui.h"
#include "ImGuizmo.h"

#include <stdio.h>

// Wrap this in a namespace to keep it separate from the C++ API.
#define DEAR_BINDINGS_INTERNAL_GLUE_CODE
namespace cimgui
{
#include "%OUTPUT_HEADER_NAME%"
}
#undef DEAR_BINDINGS_INTERNAL_GLUE_CODE
