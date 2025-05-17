const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const webview_upstream = b.dependency("webview", .{});
    const source_file = webview_upstream.path("core/src/webview.cc");

    const lib = b.addExecutable(.{
        .name = "webview",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
            .root_source_file = b.path("src/main.zig"),
        }),
    });
    lib.root_module.addIncludePath(webview_upstream.path("core/include/webview"));

    lib.root_module.addCSourceFile(.{
        .file = source_file,
        .flags = &.{"-std=c++14"},
    });
    lib.root_module.addCMacro("WEBVIEW_STATIC", "");

    inline for (.{
        "webkitgtk-6.0",
        "gtk-4.0",
        "pango-1.0",
        "fribidi",
        "harfbuzz",
        "gdk-pixbuf-2.0",
        "cairo",
        "freetype2",
        "libpng16",
        "pixman-1",
        "graphene-1.0",
        "libsoup-3.0",
        "glib-2.0",
        "libmount",
        "blkid",
        "sysprof-6",
        "X11",
    }) |include| {
        lib.root_module.addIncludePath(b.path("external/" ++ include));
    }
    lib.root_module.addIncludePath(b.path("external"));

    // attempt to prevent undefined symbol errors by defining them in stubs
    // problem: the functions from the stub are used instead of the system-installed library
    // const shared_object = b.addLibrary(.{
    //     .name = "stubs",
    //     .linkage = .dynamic,
    //     .root_module = b.createModule(.{
    //         .target = target,
    //         .optimize = optimize,
    //         .root_source_file = b.path("src/link_webkitgtk.zig"),
    //     }),
    // });
    //
    // lib.root_module.linkLibrary(shared_object);

    // requires the library to be installed on the host system;
    // creates issues for cross-compilation
    // lib.root_module.linkSystemLibrary("webkitgtk-6.0", .{});

    b.installArtifact(lib);
}
