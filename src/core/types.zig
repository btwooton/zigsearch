const std = @import("std");

pub const Document = struct {
    name: []const u8,
    text: []const u8,
    alloc: std.mem.Allocator,
    /// Define the init function for the Document struct
    pub fn init(name: []const u8, text: []const u8, allocator: std.mem.Allocator) Document {

        return Document{
            .name = name,
            .text = text,
            .alloc = allocator,
        };
    }
    /// Define the deinit function for the Document struct
    pub fn deinit(self: Document) void {
        self.alloc.free(self.text);
        self.alloc.free(self.name);
    }
};