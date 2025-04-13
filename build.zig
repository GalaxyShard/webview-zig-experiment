const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("Webview", .{
        .root_source_file = b.path("src/Webview.zig"),
    });

    const webview_upstream = b.dependency("webview", .{});
    const source_file = webview_upstream.path("core/src/webview.cc");

    const static_lib = b.addLibrary(.{
        .name = "webview-static",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    static_lib.root_module.addIncludePath(webview_upstream.path("core/include/webview"));
    static_lib.root_module.addCMacro("WEBVIEW_STATIC", "");
    switch (target.result.os.tag) {
        .windows => {
            static_lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++14"},
            });
            static_lib.root_module.addIncludePath(b.path("external/WebView2/"));
            static_lib.root_module.linkSystemLibrary("ole32", .{});
            static_lib.root_module.linkSystemLibrary("shlwapi", .{});
            static_lib.root_module.linkSystemLibrary("version", .{});
            static_lib.root_module.linkSystemLibrary("advapi32", .{});
            static_lib.root_module.linkSystemLibrary("shell32", .{});
            static_lib.root_module.linkSystemLibrary("user32", .{});
        },
        .macos => {
            static_lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++11"},
            });
            static_lib.root_module.linkFramework("WebKit", .{});
        },
        .freebsd => {
            static_lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++11"},
            });
            // static_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/cairo/" });
            // static_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/gtk-3.0/" });
            // static_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/glib-2.0/" });
            // static_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/lib/glib-2.0/include/" });
            // static_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/webkitgtk-4.1/" });
            // static_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/pango-1.0/" });
            // static_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/harfbuzz/" });
            // static_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/gdk-pixbuf-2.0/" });
            // static_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/atk-1.0/" });
            // static_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/libsoup-3.0/" });
            static_lib.root_module.linkSystemLibrary("gtk-3", .{});
            static_lib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
        },
        else => {
            static_lib.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++11"},
            });
            static_lib.root_module.linkSystemLibrary("gtk+-3.0", .{});
            static_lib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
            // static_lib.root_module.linkSystemLibrary("gtk-4", .{});
            // static_lib.root_module.linkSystemLibrary("webkit2gtk-6.0", .{});
        },
    }
    b.installArtifact(static_lib);

    const shared_lib = b.addLibrary(.{
        .name = "webview-shared",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    shared_lib.root_module.addIncludePath(webview_upstream.path("core/include/webview"));
    shared_lib.root_module.addCMacro("WEBVIEW_BUILD_SHARED", "");
    switch (target.result.os.tag) {
        .windows => {
            shared_lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++14"},
            });
            shared_lib.root_module.addIncludePath(b.path("external/WebView2"));
            shared_lib.root_module.linkSystemLibrary("ole32", .{});
            shared_lib.root_module.linkSystemLibrary("shlwapi", .{});
            shared_lib.root_module.linkSystemLibrary("version", .{});
            shared_lib.root_module.linkSystemLibrary("advapi32", .{});
            shared_lib.root_module.linkSystemLibrary("shell32", .{});
            shared_lib.root_module.linkSystemLibrary("user32", .{});
        },
        .macos => {
            shared_lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++11"},
            });
            shared_lib.root_module.linkFramework("WebKit", .{});
        },
        .freebsd => {
            shared_lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++11"},
            });
            // shared_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/cairo/" });
            // shared_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/gtk-3.0/" });
            // shared_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/glib-2.0/" });
            // shared_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/lib/glib-2.0/include/" });
            // shared_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/webkitgtk-4.1/" });
            // shared_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/pango-1.0/" });
            // shared_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/harfbuzz/" });
            // shared_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/gdk-pixbuf-2.0/" });
            // shared_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/atk-1.0/" });
            // shared_lib.root_module.addIncludePath(.{ .cwd_relative = "/usr/local/include/libsoup-3.0/" });
            shared_lib.root_module.linkSystemLibrary("gtk-3", .{});
            shared_lib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
        },
        else => {
            shared_lib.root_module.addCSourceFile(.{
                .file = source_file,
                .flags = &.{"-std=c++11"},
            });
            shared_lib.root_module.linkSystemLibrary("gtk+-3.0", .{});
            shared_lib.root_module.linkSystemLibrary("webkit2gtk-4.1", .{});
            // shared_lib.root_module.linkSystemLibrary("gtk-4", .{});
            // shared_lib.root_module.linkSystemLibrary("webkitgtk-6.0", .{});
        },
    }
    b.installArtifact(shared_lib);
}
