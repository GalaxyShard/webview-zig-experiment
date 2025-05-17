const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exported_module = b.addModule("Webview", .{
        .root_source_file = b.path("src/Webview.zig"),
    });

    const webview_upstream = b.dependency("webview", .{});
    const source_file = webview_upstream.path("core/src/webview.cc");

    const lib = b.addLibrary(.{
        .name = "webview",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    lib.root_module.addIncludePath(webview_upstream.path("core/include/webview"));

    switch (lib.linkage.?) {
        .dynamic => lib.root_module.addCMacro("WEBVIEW_BUILD_SHARED", ""),
        .static => lib.root_module.addCMacro("WEBVIEW_STATIC", ""),
    }
    switch (target.result.os.tag) {
        .windows => {
            lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++14"},
            });
            lib.root_module.addIncludePath(b.path("external/WebView2/"));
            lib.root_module.linkSystemLibrary("ole32", .{});
            lib.root_module.linkSystemLibrary("shlwapi", .{});
            lib.root_module.linkSystemLibrary("version", .{});
            lib.root_module.linkSystemLibrary("advapi32", .{});
            lib.root_module.linkSystemLibrary("shell32", .{});
            lib.root_module.linkSystemLibrary("user32", .{});
        },
        .macos => {
            lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++14"},
            });
            lib.root_module.linkFramework("WebKit", .{});
        },
        else => {
            lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++14"},
            });
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

        },
    }
    b.installArtifact(lib);

    exported_module.linkLibrary(lib);
}
