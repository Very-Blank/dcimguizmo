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
        .platforms = &[_]Platform{.GLFW},
        .renderers = &[_]Renderer{.OpenGL3},
        .docking = false,
    });

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
    dear_command.addFileArg(imgui_dependency.path("dcimgui/master/imconfig.h"));
    dear_command.addArg("--custom-namespace-prefix");
    dear_command.addArg("ImGuizmo_");
    dear_command.addArg("-o");
    dear_command.addArg("cimguizmo");

    const update = b.addUpdateSourceFiles();
    update.step.dependOn(&dear_command.step);
    update.addCopyFileToSource(tmp.path(b, "cimguizmo.cpp"), "src/cimguizmo.cpp");
    update.addCopyFileToSource(tmp.path(b, "cimguizmo.h"), "src/cimguizmo.h");

    generate_step.dependOn(&update.step);

    const cimguizmo_lib = b.addLibrary(.{
        .name = "cimguizmo",
        .root_module = init: {
            const module = b.createModule(.{
                .link_libcpp = true,
                .optimize = optimize,
                .target = target,
            });

            module.addCSourceFile(.{ .file = b.path("src/cimguizmo.cpp") });
            module.addCSourceFile(.{ .file = imguizmo_dependency.path("src/ImGuizmo.cpp") });
            module.addIncludePath(b.path("src"));
            module.addIncludePath(imguizmo_dependency.path("src/"));
            module.addIncludePath(imgui_dependency.path("dcimgui/master/"));
            module.linkLibrary(imgui_dependency.artifact("cimgui"));

            break :init module;
        },
        .linkage = .static,
    });

    b.installArtifact(cimguizmo_lib);

    // NOTE: TMP here so we can test the trnaslation with zig build
    const imgui_translate: std.Build.Module.Import = .{
        .name = "imgui",
        .module = init_imgui_module: {
            const imgui_path = imgui_dependency.path("dcimgui/docking/");

            const write_files = b.addWriteFiles();
            const imgui_header = write_files.add("imgui_all.h",
                \\#include "dcimgui.h"
                \\#include "backends/dcimgui_impl_glfw.h"
                \\#include "backends/dcimgui_impl_opengl3.h"
                \\#include "cimguizmo.h"
            );

            const translate_c = b.addTranslateC(.{
                .root_source_file = imgui_header,
                .link_libc = true,
                .optimize = optimize,
                .target = target,
            });

            translate_c.addIncludePath(b.path("src/"));
            translate_c.addIncludePath(imgui_path);
            translate_c.addIncludePath(imgui_path.path(b, "backends"));

            break :init_imgui_module translate_c.addModule("dfd");
        },
    };

    const exe = b.addExecutable(.{
        .name = "FAKE",
        .root_module = init_exe_module: {
            const exe_module = b.createModule(.{
                .root_source_file = b.path("src/main.zig"),
                .target = target,
                .optimize = optimize,
                .imports = &.{imgui_translate},
            });

            exe_module.linkLibrary(imgui_dependency.artifact("cimgui"));
            exe_module.linkLibrary(cimguizmo_lib);

            break :init_exe_module exe_module;
        },
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}
