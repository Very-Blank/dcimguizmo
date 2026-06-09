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
    dear_command.addFileArg(imgui_dependency.path("dcimgui/master/imconfig.h"));
    dear_command.addArg("-o");
    dear_command.addArg("cimguizmo");

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

    cimguizmo_lib.step.dependOn(&dear_command.step);

    const isntall_file = b.addInstallFile(tmp.path(b, "cimguizmo.h"), "cimguizmo.h");
    isntall_file.step.dependOn(&dear_command.step);
    b.getInstallStep().dependOn(&isntall_file.step);

    b.installArtifact(cimguizmo_lib);
}
