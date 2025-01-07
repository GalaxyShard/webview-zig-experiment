const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("webview", .{
        .root_source_file = b.path("src/webview.zig"),
    });

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const webview_upstream = b.dependency("webview", .{});

    const source_file = webview_upstream.path("core/src/webview.cc");

    const static_lib = b.addStaticLibrary(.{
        .name = "webview-static",
        .optimize = optimize,
        .target = target,
    });
    static_lib.addIncludePath(webview_upstream.path("core/include/webview"));
    static_lib.root_module.addCMacro("WEBVIEW_STATIC", "");
    static_lib.linkLibCpp();
    switch (target.result.os.tag) {
        .windows => {
            static_lib.addCSourceFile(.{ .file = source_file, .flags = &.{"-std=c++14"} });
            static_lib.addIncludePath(b.path("external/WebView2/"));
            static_lib.linkSystemLibrary("ole32");
            static_lib.linkSystemLibrary("shlwapi");
            static_lib.linkSystemLibrary("version");
            static_lib.linkSystemLibrary("advapi32");
            static_lib.linkSystemLibrary("shell32");
            static_lib.linkSystemLibrary("user32");
        },
        .macos => {
            static_lib.addCSourceFile(.{ .file = source_file, .flags = &.{"-std=c++11"} });
            static_lib.linkFramework("WebKit");
        },
        .freebsd => {
            static_lib.addCSourceFile(.{ .file = source_file, .flags = &.{"-std=c++11"} });
//             static_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/cairo/" });
//             static_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/gtk-3.0/" });
//             static_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/glib-2.0/" });
//             static_lib.addIncludePath(.{ .cwd_relative = "/usr/local/lib/glib-2.0/include/" });
//             static_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/webkitgtk-4.0/" });
//             static_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/pango-1.0/" });
//             static_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/harfbuzz/" });
//             static_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/gdk-pixbuf-2.0/" });
//             static_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/atk-1.0/" });
//             static_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/libsoup-3.0/" });
            static_lib.linkSystemLibrary("gtk-3");
            static_lib.linkSystemLibrary("webkit2gtk-4.0");
        },
        else => {
            static_lib.addCSourceFile(.{ .file = source_file, .flags = &.{"-std=c++11"} });
            static_lib.linkSystemLibrary("gtk+-3.0");
            static_lib.linkSystemLibrary("webkit2gtk-4.0");
//             static_lib.linkSystemLibrary("gtk-4");
//             static_lib.linkSystemLibrary("webkitgtk-6.0");
        },
    }
    b.installArtifact(static_lib);

    const shared_lib = b.addSharedLibrary(.{
        .name = "webview-shared",
        .optimize = optimize,
        .target = target,
    });
    shared_lib.addIncludePath(webview_upstream.path("core/include/webview"));
    shared_lib.root_module.addCMacro("WEBVIEW_BUILD_SHARED", "");
    shared_lib.linkLibCpp();
    switch (target.result.os.tag) {
        .windows => {
            shared_lib.addCSourceFile(.{ .file = source_file, .flags = &.{"-std=c++14"} });
            shared_lib.addIncludePath(b.path("external/WebView2"));
            shared_lib.linkSystemLibrary("ole32");
            shared_lib.linkSystemLibrary("shlwapi");
            shared_lib.linkSystemLibrary("version");
            shared_lib.linkSystemLibrary("advapi32");
            shared_lib.linkSystemLibrary("shell32");
            shared_lib.linkSystemLibrary("user32");
        },
        .macos => {
            shared_lib.addCSourceFile(.{ .file = source_file, .flags = &.{"-std=c++11"} });
            shared_lib.linkFramework("WebKit");
        },
        .freebsd => {
            shared_lib.addCSourceFile(.{ .file = source_file, .flags = &.{"-std=c++11"} });
//             shared_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/cairo/" });
//             shared_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/gtk-3.0/" });
//             shared_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/glib-2.0/" });
//             shared_lib.addIncludePath(.{ .cwd_relative = "/usr/local/lib/glib-2.0/include/" });
//             shared_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/webkitgtk-4.0/" });
//             shared_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/pango-1.0/" });
//             shared_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/harfbuzz/" });
//             shared_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/gdk-pixbuf-2.0/" });
//             shared_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/atk-1.0/" });
//             shared_lib.addIncludePath(.{ .cwd_relative = "/usr/local/include/libsoup-3.0/" });
            shared_lib.linkSystemLibrary("gtk-3");
            shared_lib.linkSystemLibrary("webkit2gtk-4.0");
        },
        else => {
            shared_lib.addCSourceFile(.{ .file = source_file, .flags = &.{"-std=c++11"} });
            shared_lib.linkSystemLibrary("gtk+-3.0");
            shared_lib.linkSystemLibrary("webkit2gtk-4.0");
        },
    }
    b.installArtifact(shared_lib);
}
