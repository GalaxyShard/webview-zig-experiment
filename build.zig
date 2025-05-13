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
        .freebsd => {
            lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++14"},
            });
            lib.root_module.linkSystemLibrary("gtk-3", .{});
            lib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
        },
        else => {
            lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++14"},
            });
            lib.root_module.linkSystemLibrary("gtk+-3.0", .{});
            lib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
            // lib.root_module.linkSystemLibrary("gtk-4", .{});
            // lib.root_module.linkSystemLibrary("webkitgtk-6.0", .{});
        },
    }
    b.installArtifact(lib);

    exported_module.linkLibrary(lib);
}
