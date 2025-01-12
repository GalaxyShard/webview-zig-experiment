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

const Webview = @This();

pub const Handle = opaque{};
pub const RawDispatchCallback = fn (Webview, ?*anyopaque) void;
pub const LibraryVersion = extern struct {
    major: c_uint,
    minor: c_uint,
    patch: c_uint,
};
pub const VersionInfo = extern struct {
    version: LibraryVersion,
    version_number: [32]u8,
    pre_release: [48]u8,
    build_metadata: [48]u8,
};


/// Quoted from webview:
///     The following codes are commonly used in the library:
///     - ok
///     - unspecified
///     - invalid_argument
///     - invalid_state
///
///     With the exception of "ok" which is normally expected,
///     the other common codes do not normally need to be handled specifically.
///     Refer to specific functions regarding handling of other codes.
///
const CApiReturn = enum(c_int) {
    missing_dependency = -5,
    canceled = -4,
    invalid_state = -3,

    /// One or more invalid arguments have been specified e.g. in a function call.
    invalid_argument = -2,

    /// An unspecified error occurred. A more specific error code may be needed.
    unspecified = -1,

    ok = 0,
    duplicate = 1,
    not_found = 2
};

const raw = struct {
    extern fn webview_create(debug: c_int, window: ?*anyopaque) ?*Handle;
    extern fn webview_destroy(w: *Handle) CApiReturn;
    extern fn webview_run(w: *Handle) CApiReturn;
    extern fn webview_terminate(w: *Handle) CApiReturn;
    extern fn webview_dispatch(w: *Handle, @"fn": *const fn (*Handle, ?*anyopaque) callconv(.C) void, arg: ?*anyopaque) CApiReturn;
    extern fn webview_get_window(w: *Handle) ?*anyopaque;
    extern fn webview_set_title(w: *Handle, title: [*:0]const u8) CApiReturn;
    extern fn webview_set_size(w: *Handle, width: c_int, height: c_int, hints: c_int) CApiReturn;
    extern fn webview_navigate(w: *Handle, url: [*:0]const u8) CApiReturn;
    extern fn webview_set_html(w: *Handle, html: [*:0]const u8) CApiReturn;
    extern fn webview_init(w: *Handle, js: [*:0]const u8) CApiReturn;
    extern fn webview_eval(w: *Handle, js: [*:0]const u8) CApiReturn;
    extern fn webview_bind(w: *Handle, name: [*:0]const u8, @"fn": *const fn ([*:0]const u8, [*:0]const u8, ?*anyopaque) callconv(.C) void, arg: ?*anyopaque) CApiReturn;
    extern fn webview_unbind(w: *Handle, name: [*:0]const u8) CApiReturn;
    extern fn webview_return(w: *Handle, id: [*:0]const u8, status: c_int, result: [*:0]const u8) CApiReturn;
    extern fn webview_version() *const VersionInfo;
};

handle: *Handle,

pub const Error = error {
    /// Invalid state detected.
    InvalidState,
    /// An unspecified error occurred. A more specific error code may be needed.
    Unspecified,
};
// Windows: WebView2 is not installed.
// pub const CreateError = error{MissingDependency} || Error;

// Checked with upstream webview as of 2025-01-12
pub const BindError = error {Duplicate,OutOfMemory} || Error;
pub const UnbindError = error {NotFound} || Error;

pub fn genericReturnToError(value: CApiReturn) Error!void {
    return switch (value) {
        // 2025-01-12: Never actually returned; converted to nullptr before returning
        .missing_dependency => unreachable,

        // 2025-01-12: Never actually returned; converted to nullptr before returning
        // Additionally this is not documented as a return value
        .canceled => unreachable,

        .invalid_state => error.InvalidState,

        // only returned if a pointer is null or a integer outside the enum range
        // is specified, both of which are prevented by Zig's type system
        .invalid_argument => unreachable,

        .unspecified => error.Unspecified,
        .ok => void{},

        // Function does not handle BindError/UnbindError
        .duplicate => unreachable,
        .not_found => unreachable,
    };
}

pub const BindContext = struct {
    webview: Webview,
    alloc: std.mem.Allocator,
    id: [:0]const u8,

    pub fn returnValue(self: BindContext, value: anytype) (error{OutOfMemory} || Error)!void {
        return self.returnGeneric(0, value);
    }

    pub fn returnError(self: BindContext, value: anytype) (error{OutOfMemory} || Error)!void {
        return self.returnGeneric(1, value);
    }

    /// status: zero for success, non-zero for error
    pub fn returnGeneric(self: BindContext, status: i32, value: anytype) (error{OutOfMemory} || Error)!void {
        if (@TypeOf(value) == void) {
            return self.returnRaw(status, "");
        }
        var buffer = std.ArrayList(u8).init(self.alloc);
        defer buffer.deinit();

        try std.json.stringifyArbitraryDepth(self.alloc, value, .{}, buffer.writer());

        const json = try buffer.toOwnedSliceSentinel(0);
        defer self.alloc.free(json);

        return self.returnRaw(status, json);
    }

    /// status: zero for success, non-zero for error
    /// json: a json encoded string to be passed to Javascript, or the empty string to pass a Javascript `undefined`
    pub fn returnRaw(self: BindContext, status: i32, json: [:0]const u8) Error!void {
        return genericReturnToError(raw.webview_return(self.webview.handle, self.id.ptr, status, json.ptr));
    }
};

pub const WindowSizeHint = enum(c_int) {
    none = 0,
    min = 1,
    max = 2,
    fixed = 3
};

pub fn init(debug: bool, window: ?*anyopaque) ?Webview {
    const handle = raw.webview_create(@intFromBool(debug), window) orelse return null;
    return .{ .handle = handle };
}

pub fn run(self: Webview) Error!void {
    return genericReturnToError(raw.webview_run(self.handle));
}

pub fn terminate(self: Webview) Error!void {
    return genericReturnToError(raw.webview_terminate(self.handle));
}

pub fn dispatch(self: Webview, func: anytype, context: ?*anyopaque) Error!void {
    // TODO: rework this api
    return genericReturnToError(raw.webview_dispatch(self.handle, func, context));
}

pub fn getWindow(self: Webview) ?*anyopaque {
    return raw.webview_get_window(self.handle);
}

pub fn setTitle(self: Webview, title: [:0]const u8) Error!void {
    return genericReturnToError(raw.webview_set_title(self.handle, title.ptr));
}

pub fn setSize(self: Webview, width: i32, height: i32, hint: WindowSizeHint) Error!void {
    return genericReturnToError(raw.webview_set_size(self.handle, width, height, @intFromEnum(hint)));
}

pub fn navigate(self: Webview, url: [:0]const u8) Error!void {
    return genericReturnToError(raw.webview_navigate(self.handle, url.ptr));
}

pub fn setHtml(self: Webview, html: [:0]const u8) Error!void {
    return genericReturnToError(raw.webview_set_html(self.handle, html.ptr));
}

pub fn inject_preload_js(self: Webview, js: [:0]const u8) Error!void {
    return genericReturnToError(raw.webview_init(self.handle, js.ptr));
}

pub fn eval(self: Webview, js: [:0]const u8) Error!void {
    return genericReturnToError(raw.webview_eval(self.handle, js.ptr));
}

pub const Binding = struct {
    webview: Webview,
    name: [:0]const u8,
    internal_context: *anyopaque,
    deinit_context: *const fn(internal_context: *anyopaque) void,

    pub fn deinit(self: Binding) void {
        // Confirmed against webview as of 2025-01-10, this should never fail
        // unless self.webview.handle or self.name are null (prevented by Zig's type checking)
        // or if the function wasn't bound (possibly a double-free; an error either way)
        std.debug.assert(raw.webview_unbind(self.webview.handle, self.name.ptr) == .ok);
        self.deinit_context(self.internal_context);

    }
};

pub fn bind(self: Webview, alloc: std.mem.Allocator, name: [:0]const u8, func: anytype, user_context: anytype) BindError!Binding {
    const InternalContext = struct {
        webview: Webview,
        alloc: std.mem.Allocator,
        name: [:0]const u8,
        func: @TypeOf(func),
        user_context: @TypeOf(user_context),
    };

    const incorrect_type_msg = std.fmt.comptimePrint(
        "expected function type '*const fn(...) void', found '{s}'",
        .{ @typeName(@TypeOf(func)) },
    );
    const info = switch (@typeInfo(@TypeOf(func))) {
        .pointer => |p| (
            switch (@typeInfo(p.child)) {
                .@"fn" => |i| i,
                else => @compileError(incorrect_type_msg),
            }
        ),
        else => @compileError(incorrect_type_msg),
    };

    if (info.is_var_args or (info.params.len != 3 and info.params.len != 2)) {
        const msg = (
                \\`func` must have either 2 or 3 arguments
                \\     2 args: fn(context: BindContext, data: {0s}) void
                \\     3 args: fn(context: BindContext, args: <some type>, data: {0s}) void
        );
        @compileError(std.fmt.comptimePrint(msg, .{ @typeName(@TypeOf(user_context)) }));
    }
    const LastArgumentType = info.params[info.params.len - 1].type.?;
    if (@TypeOf(user_context) != LastArgumentType) {
        @compileError(std.fmt.comptimePrint("last argument of 'func' ({s}) must be the same type as 'user_context' ({s})", .{
            @typeName(@TypeOf(user_context)), @typeName(LastArgumentType)
        }));
    }
    if (info.return_type.? != void) {
        @compileError(std.fmt.comptimePrint("bind function must return 'void', found '{s}'; try using bind_context.returnValue(...) instead", .{
            @typeName(info.return_type.?),
        }));
    }

    const callback = struct {
        fn inner(id: [*:0]const u8, json: [*:0]const u8, context_raw: ?*anyopaque) callconv(.c) void {

            const internal_context: *InternalContext = @alignCast(@ptrCast(context_raw.?));

            const bind_context: BindContext = .{
                .webview = internal_context.webview,
                .alloc = internal_context.alloc,
                .id = std.mem.sliceTo(id, 0),
            };
            const ArgsType = info.params[1].type.?;

            if (info.params.len == 2) {
                internal_context.func(bind_context, internal_context.user_context);
            } else {
                const json_slice = std.mem.sliceTo(json, 0);
                const parsed = std.json.parseFromSlice(ArgsType, internal_context.alloc, json_slice, .{}) catch |e| {
                    std.debug.panic("(function {s}) error parsing json: {s}\njson: {s}\n", .{
                        internal_context.name, @errorName(e), json_slice
                    });
                };
                defer parsed.deinit();
                internal_context.func(bind_context, parsed.value, internal_context.user_context);
            }
        }
    }.inner;
    const deinit = struct {
        fn inner(internal_context: *anyopaque) void {
            const casted: *InternalContext = @alignCast(@ptrCast(internal_context));
            casted.alloc.destroy(casted);
        }
    }.inner;
    const context = try alloc.create(InternalContext);
    context.* = .{
        .webview = self,
        .alloc = alloc,
        .name = name,
        .func = func,
        .user_context = user_context,

    };
    const possible_error = raw.webview_bind(self.handle, name.ptr, callback, context);
    try switch (possible_error) {
        .ok => void{},
        // 2025-01-12: missing_dependency & canceled are not possible return values
        // invalid_argument is only caused by null values, prevented by type-checking
        .missing_dependency, .canceled, .invalid_argument => unreachable,

        .invalid_state => error.InvalidState,
        .unspecified => error.Unspecified,
        .duplicate => error.Duplicate,

        // Function does not handle UnbindError
        .not_found => unreachable,
    };
    return .{
        .webview = self,
        .name = name,
        .internal_context = context,
        .deinit_context = &deinit,
    };
}

pub fn version() *const VersionInfo {
    return raw.webview_version();
}

pub fn destroy(self: Webview) void {
    // Confirmed against webview as of 2025-01-08, this should never fail
    // unless self.handle is null, which is prevented by Zig's type checking
    std.debug.assert(raw.webview_destroy(self.handle) == .ok);
}
