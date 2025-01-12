# zig-webview

Zig binding for a tiny cross-platform **webview** library to build modern cross-platform GUIs.

### Requirements

 - [Zig Compiler](https://ziglang.org/) - **0.14.0-dev**
 - Unix
   - [GTK](https://gtk.org/) and [WebKitGTK](https://webkitgtk.org/)
 - Windows
   - [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
 - macOS
   - [WebKit](https://webkit.org/)

### 

```sh
zig fetch --save git+https://codeberg.org/GalaxyShard/zig-webview
```

`build.zig`:

```zig
const webview = b.dependency("webview", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("Webview", webview.module("Webview"));
exe.linkLibrary(webview.artifact("webview-static")); // or "webview-shared" for shared library
// exe.linkSystemLibrary("webview"); // to link with installed prebuilt library without building
```

### References
 - [webview](https://github.com/webview/webview)

### License

This repo is released under the [MIT License](LICENSE).

Third party code:
 - webview is licensed under the [MIT License](https://github.com/webview/webview/blob/master/LICENSE).
 - [external/WebView2](external/WebView2) licensed under the [BSD-3-Clause License](external/WebView2/LICENSE).
