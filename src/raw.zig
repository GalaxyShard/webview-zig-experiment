// Copyright (c) 2023 XXIV
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


/// The following codes are commonly used in the library:
/// - ok
/// - unspecified
/// - invalid_argument
/// - invalid_state
///
/// With the exception of "ok" which is normally expected,
/// the other common codes do not normally need to be handled specifically.
/// Refer to specific functions regarding handling of other codes.
///
pub const WebviewReturn = enum(c_int) {
    /// Missing dependency.
    missing_dependency = -5,
    /// Operation canceled.
    canceled = -4,
    /// Invalid state detected.
    invalid_state = -3,
    /// One or more invalid arguments have been specified e.g. in a function call.
    invalid_argument = -2,
    /// An unspecified error occurred. A more specific error code may be needed.
    unspecified = -1,
    /// OK/Success. Functions that return error codes will typically return this
    /// to signify successful operations.
    ok = 0,
    /// Signifies that something already exists.
    duplicate = 1,
    /// Signifies that something does not exist.
    not_found = 2
};

pub const WebviewVersion = extern struct {
    major: c_uint,
    minor: c_uint,
    patch: c_uint,
};
pub const WebviewVersionInfo = extern struct {
    version: WebviewVersion,
    version_number: [32]u8,
    pre_release: [48]u8,
    build_metadata: [48]u8,
};
pub const webview_t = *anyopaque;
pub extern fn webview_create(debug: c_int, window: ?*anyopaque) ?webview_t;
pub extern fn webview_destroy(w: webview_t) WebviewReturn;
pub extern fn webview_run(w: webview_t) WebviewReturn;
pub extern fn webview_terminate(w: webview_t) WebviewReturn;
pub extern fn webview_dispatch(w: webview_t, @"fn": *const fn (webview_t, ?*anyopaque) callconv(.C) void, arg: ?*anyopaque) WebviewReturn;
pub extern fn webview_get_window(w: webview_t) ?*anyopaque;
pub extern fn webview_set_title(w: webview_t, title: [*:0]const u8) WebviewReturn;
pub extern fn webview_set_size(w: webview_t, width: c_int, height: c_int, hints: c_int) WebviewReturn;
pub extern fn webview_navigate(w: webview_t, url: [*:0]const u8) WebviewReturn;
pub extern fn webview_set_html(w: webview_t, html: [*:0]const u8) WebviewReturn;
pub extern fn webview_init(w: webview_t, js: [*:0]const u8) WebviewReturn;
pub extern fn webview_eval(w: webview_t, js: [*:0]const u8) WebviewReturn;
pub extern fn webview_bind(w: webview_t, name: [*:0]const u8, @"fn": ?*const fn ([*:0]const u8, [*:0]const u8, ?*anyopaque) callconv(.C) void, arg: ?*anyopaque) WebviewReturn;
pub extern fn webview_unbind(w: webview_t, name: [*:0]const u8) WebviewReturn;
pub extern fn webview_return(w: webview_t, id: [*:0]const u8, status: c_int, result: [*:0]const u8) WebviewReturn;
pub extern fn webview_version() *const WebviewVersionInfo;
