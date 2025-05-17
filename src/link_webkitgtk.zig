// Copyright (c) 2025 Dominic Adragna
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

export fn gdk_display_get_default() void {}
export fn gdk_x11_display_get_type() void {}

export fn g_free() void {}
export fn g_idle_add_full() void {}
export fn g_main_context_iteration() void {}
export fn g_object_ref_sink() void {}
export fn g_object_unref() void {}
export fn g_signal_connect_data() void {}
export fn g_signal_handlers_disconnect_matched() void {}

export fn gtk_init_check() void {}
export fn gtk_widget_get_type() void {}
export fn gtk_widget_grab_focus() void {}
export fn gtk_widget_set_size_request() void {}
export fn gtk_widget_set_visible() void {}
export fn gtk_window_close() void {}
export fn gtk_window_get_child() void {}
export fn gtk_window_get_type() void {}
export fn gtk_window_new() void {}
export fn gtk_window_set_child() void {}
export fn gtk_window_set_default_size() void {}
export fn gtk_window_set_resizable() void {}
export fn gtk_window_set_title() void {}

export fn g_type_check_instance_cast() void {}
export fn g_type_check_instance_is_a() void {}

export fn jsc_value_to_string() void {}

export fn webkit_get_major_version() void {}
export fn webkit_get_minor_version() void {}
export fn webkit_settings_set_enable_developer_extras() void {}
export fn webkit_settings_set_enable_write_console_messages_to_stdout() void {}
export fn webkit_settings_set_javascript_can_access_clipboard() void {}
export fn webkit_user_content_manager_add_script() void {}
export fn webkit_user_content_manager_register_script_message_handler() void {}
export fn webkit_user_content_manager_remove_all_scripts() void {}
export fn webkit_user_script_new() void {}
export fn webkit_user_script_ref() void {}
export fn webkit_user_script_unref() void {}
export fn webkit_web_view_evaluate_javascript() void {}
export fn webkit_web_view_get_settings() void {}
export fn webkit_web_view_get_type() void {}
export fn webkit_web_view_get_uri() void {}
export fn webkit_web_view_get_user_content_manager() void {}
export fn webkit_web_view_load_html() void {}
export fn webkit_web_view_load_uri() void {}
export fn webkit_web_view_new() void {}
