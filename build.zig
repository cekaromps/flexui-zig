const std = @import("std");
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const flexui_module = b.addModule("flexui", .{
        .root_source_file = b.path("src/flexui.zig"),
        .target = target,
        .optimize = optimize,
    });
    flexui_module.addImport("raylib", raylib);
    flexui_module.linkLibrary(raylib_artifact);

    const lib_module = b.createModule(.{
        .root_source_file = b.path("src/flexui.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_module.addImport("raylib", raylib);
    lib_module.linkLibrary(raylib_artifact);

    const lib = b.addLibrary(.{
        .name = "flexui",
        .linkage = .static,
        .root_module = lib_module,
    });
    b.installArtifact(lib);

   //const build_examples = b.option(bool, "examples", "Build examples") orelse true;
   //if (build_examples) {
   //    const example_module = b.createModule(.{
   //        .root_source_file = b.path("examples/basic/main.zig"),
   //        .target = target,
   //        .optimize = optimize,
   //    });
   //    example_module.addImport("flexui", flexui_module);
   //    example_module.addImport("raylib", raylib);
   //    example_module.linkLibrary(raylib_artifact);

   //    const example_exe = b.addExecutable(.{
   //        .name = "flexui_basic_example",
   //        .root_module = example_module,
   //    });
   //    b.installArtifact(example_exe);
   //}
}
