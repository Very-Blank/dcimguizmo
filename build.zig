const std = @import("std");
const cimgui = @import("cimgui_zig");
const Renderer = cimgui.Renderer;
const Platform = cimgui.Platform;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const imgui_dependency = b.dependency("cimgui_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const imguizmo_dependency = b.dependency("imguizmo", .{});

    const dear_bindings = imgui_dependency.builder.dependency("dcimgui", .{});

    const add_files = b.addTempFiles();
    _ = add_files.addCopyFile(b.path("dear_bindings/src/templates/ImGuizmo-header-template.cpp"), "ImGuizmo-header-template.cpp");
    _ = add_files.addCopyFile(b.path("dear_bindings/src/templates/ImGuizmo-header-template.h"), "ImGuizmo-header-template.h");
    _ = add_files.addCopyFile(dear_bindings.path("src/templates/common-header-template.h"), "common-header-template.h");
    _ = add_files.addCopyFile(dear_bindings.path("src/templates/common-header-template.cpp"), "common-header-template.cpp");

    const sanitize_imguizmo = b.addSystemCommand(&.{
        "python3",
        b.path("clean.py").getPath(b),
    });

    sanitize_imguizmo.addFileArg(imguizmo_dependency.path("src/ImGuizmo.h"));

    const sanitized_header = sanitize_imguizmo.addOutputFileArg("ImGuizmo.h");

    const tmp = b.tmpPath();
    const run_python = b.addSystemCommand(&.{"python3"});
    run_python.setCwd(tmp);
    run_python.addFileArg(dear_bindings.path("dear_bindings.py"));
    run_python.addFileArg(sanitized_header);
    run_python.addArg("-t");
    run_python.addDirectoryArg(add_files.getDirectory());
    run_python.addArg("--imconfig-path");
    run_python.addFileArg(imgui_dependency.path("dcimgui/master/imconfig.h"));
    run_python.addArg("-o");
    run_python.addArg("cimguizmo");

    // FIXME: this doesn't wait for the generation to be done
    const cimguizmo_lib = b.addLibrary(.{
        .name = "cimguizmo",
        .root_module = init: {
            const module = b.createModule(.{
                .link_libcpp = true,
                .optimize = optimize,
                .target = target,
            });

            module.addCSourceFile(.{ .file = tmp.path(b, "cimguizmo.cpp") });
            module.addIncludePath(tmp);
            module.addIncludePath(imguizmo_dependency.path("src/"));
            module.addIncludePath(imgui_dependency.path("dcimgui/master/"));
            module.linkLibrary(imgui_dependency.artifact("cimgui"));

            break :init module;
        },
        .linkage = .static,
    });

    cimguizmo_lib.step.dependOn(&run_python.step);

    // install
    // └─ install cimguizmo
    //    └─ compile lib cimguizmo Debug native 1 errors
    // error: failed to check cache: '.zig-cache/o/99156590def1e7352807d4d7d9beb15c/cimguizmo/cimguizmo.cpp' file_hash FileNotFound

    b.installArtifact(cimguizmo_lib);
}
