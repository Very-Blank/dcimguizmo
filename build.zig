const std = @import("std");
const cimgui = @import("cimgui_zig");
const Renderer = cimgui.Renderer;
const Platform = cimgui.Platform;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const imqui_dependency = b.dependency("cimgui_zig", .{
        .target = target,
        .optimize = optimize,
        .platforms = &[_]Platform{.GLFW},
        .renderers = &[_]Renderer{.OpenGL3},
    });

    const imguizmo_dependency = b.dependency("imguizmo", .{});

    const cimguizmo_lib = b.addLibrary(.{
        .name = "cimguizmo",
        .root_module = init: {
            const module = b.createModule(.{
                .link_libcpp = true,
                .optimize = optimize,
                .target = target,
            });

            module.addCSourceFile(.{
                .file = b.path("src/cimguizmo.cpp"),
            });
            module.addIncludePath(b.path("src/"));

            module.addIncludePath(imguizmo_dependency.path("src/"));
            module.linkLibrary(imqui_dependency.artifact("imgui"));

            break :init module;
        },
        .linkage = .static,
    });

    b.installArtifact(cimguizmo_lib);
}
