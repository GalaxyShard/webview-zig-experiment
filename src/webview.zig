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
const std = @import("std");
const fmt = std.fmt;
const mem = std.mem;
pub const raw = @import("raw.zig");

pub const Error = error {
    // Missing dependency.
    MissingDependency,
    // Operation canceled.
    Canceled,
    /// Invalid state detected.
    InvalidState,
    /// One or more invalid arguments have been specified e.g. in a function call.
    InvalidArgument,
    /// An unspecified error occurred. A more specific error code may be needed.
    Unspecified,
    // Signifies that something already exists.
    Duplicate,
    // Signifies that something does not exist.
    NotFound,
};
pub fn rawReturnToError(value: raw.WebviewReturn) Error!void {
    return switch (value) {
        .missing_dependency =>  error.MissingDependency,
        .canceled => error.Canceled,
        .invalid_state =>  error.InvalidState,
        .invalid_argument =>  error.InvalidArgument,
        .unspecified => error.Unspecified,
        .ok => void{},
        .duplicate => error.Duplicate,
        .not_found => error.NotFound,
    };
}

pub const Webview = struct {
    
    handle: raw.webview_t,

    const Self = @This();

    pub const VersionInfo = raw.WebviewVersionInfo;
    pub const DispatchCallback = fn (Webview, ?*anyopaque) void;
    pub const BindCallback = fn ([:0]const u8, [:0]const u8, ?*anyopaque) void;

    pub const WindowSizeHint = enum(c_int) {
        none = 0,
        min = 1,
        max = 2,
        fixed = 3
    };

    pub fn create(debug: bool, window: ?*anyopaque) ?Self {
        const handle = raw.webview_create(@intFromBool(debug), window) orelse return null;
        return .{ .handle = handle };
    }

    pub fn run(self: Self) Error!void {
        return rawReturnToError(raw.webview_run(self.handle));
    }

    pub fn terminate(self: Self) Error!void {
        return rawReturnToError(raw.webview_terminate(self.handle));
    }
    
    pub fn dispatch(self: Self, func: anytype, context: ?*anyopaque) Error!void {
        // TODO: rework this api
        return rawReturnToError(raw.webview_dispatch(self.handle, func, context));
    }
    
    pub fn getWindow(self: Self) ?*anyopaque {
        return raw.webview_get_window(self.handle);
    }
    
    pub fn setTitle(self: Self, title: [:0]const u8) Error!void {
        return rawReturnToError(raw.webview_set_title(self.handle, title.ptr));
    }

    pub fn setSize(self: Self, width: i32, height: i32, hint: WindowSizeHint) Error!void {
        return rawReturnToError(raw.webview_set_size(self.handle, width, height, @intFromEnum(hint)));
    }
    
    pub fn navigate(self: Self, url: [:0]const u8) Error!void {
        return rawReturnToError(raw.webview_navigate(self.handle, url.ptr));
    }
    
    pub fn setHtml(self: Self, html: [:0]const u8) Error!void {
        return rawReturnToError(raw.webview_set_html(self.handle, html.ptr));
    }
    
    pub fn init(self: Self, js: [:0]const u8) Error!void {
        return rawReturnToError(raw.webview_init(self.handle, js.ptr));
    }
    
    pub fn eval(self: Self, js: [:0]const u8) Error!void {
        return rawReturnToError(raw.webview_eval(self.handle, js.ptr));
    }
    
    pub fn bind(self: Self, name: [:0]const u8, func: anytype, context: ?*anyopaque) Error!void {
        const wrapper = struct {
            fn inner(seq: [*:0]const u8, req: [*:0]const u8, context_inner: ?*anyopaque) callconv(.c) void {
                @call(.auto, func, .{mem.sliceTo(seq, 0), mem.sliceTo(req, 0), context_inner});
            }
        };
        return rawReturnToError(raw.webview_bind(self.handle, name.ptr, wrapper.inner, context));
    }
    
    pub fn unbind(self: Self, name: [:0]const u8) Error!void {
        return rawReturnToError(raw.webview_unbind(self.handle, name.ptr));
    }
    
    /// id: must be the value passed into bind callback
    /// status: zero for success, non-zero for error
    /// result: a json encoded string to be passed to Javascript
    pub fn returnRaw(self: Self, id: [:0]const u8, status: i32, result: [:0]const u8) Error!void {
        return rawReturnToError(raw.webview_return(self.handle, id.ptr, status, result.ptr));
    }

    /// id: must be value passed into bind callback
    /// status: zero for success, non-zero for error
    pub fn returnValue(self: Self, alloc: std.mem.Allocator, id: [:0]const u8, status: i32, value: anytype) (std.mem.Allocator.Error || Error)!void {
        var buffer = std.ArrayList(u8).init(alloc);
        defer buffer.deinit();
        try std.json.stringifyArbitraryDepth(alloc, value, .{}, buffer.writer());
        const json = try buffer.toOwnedSliceSentinel(0);

        return self.returnRaw(self.handle, id, status, json);
    }

    pub fn version() *const VersionInfo {
        return raw.webview_version();
    }

    pub fn destroy(self: Self) void {
        // As of 2025-01-08, this should never fail unless self.handle is null,
        // which is prevented by Zig's type checking
        std.debug.assert(raw.webview_destroy(self.handle) == .ok);
    }
};
