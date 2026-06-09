const std = @import("std");
const cimgui = @import("cimgui_zig");
const Renderer = cimgui.Renderer;
const Platform = cimgui.Platform;

pub fn build(b: *std.Build) void {
    const docking = b.option(bool, "docking", "master or docking ocornut/imgui branch?") orelse false;

    const imgui_dependency = b.dependency("cimgui_zig", .{});

    const imguizmo_dependency = b.dependency("imguizmo", .{});

    const generate_step = b.step("generate", "Generate C bindings for ImGuizmo");

    const dear_bindings = imgui_dependency.builder.dependency("dcimgui", .{});

    const add_files = b.addTempFiles();
    _ = add_files.addCopyFile(b.path("dear_bindings/src/templates/ImGuizmo-header-template.cpp"), "ImGuizmo-header-template.cpp");
    _ = add_files.addCopyFile(b.path("dear_bindings/src/templates/ImGuizmo-header-template.h"), "ImGuizmo-header-template.h");
    _ = add_files.addCopyFile(dear_bindings.path("src/templates/common-header-template.h"), "common-header-template.h");
    _ = add_files.addCopyFile(dear_bindings.path("src/templates/common-header-template.cpp"), "common-header-template.cpp");

    const clean_command = b.addSystemCommand(&.{"python3"});
    clean_command.addFileArg(b.path("clean.py"));
    clean_command.addFileArg(imguizmo_dependency.path("src/ImGuizmo.h"));

    const clean_header = clean_command.addOutputFileArg("ImGuizmo.h");

    const tmp = b.tmpPath();
    const dear_command = b.addSystemCommand(&.{"python3"});
    dear_command.step.dependOn(&clean_command.step);

    dear_command.setCwd(tmp);
    dear_command.addFileArg(dear_bindings.path("dear_bindings.py"));
    dear_command.addFileArg(clean_header);
    dear_command.addArg("-t");
    dear_command.addDirectoryArg(add_files.getDirectory());
    dear_command.addArg("--imconfig-path");
    dear_command.addFileArg(imgui_dependency.path(if (docking) "dcimgui/docking/imconfig.h" else "dcimgui/master/imconfig.h"));
    dear_command.addArg("--custom-namespace-prefix");
    dear_command.addArg("ImGuizmo_");
    dear_command.addArg("-o");
    dear_command.addArg("cimguizmo");

    const update = b.addUpdateSourceFiles();
    update.step.dependOn(&dear_command.step);
    update.addCopyFileToSource(tmp.path(b, "cimguizmo.cpp"), "src/cimguizmo.cpp");
    update.addCopyFileToSource(tmp.path(b, "cimguizmo.h"), "src/cimguizmo.h");

    generate_step.dependOn(&update.step);
}
