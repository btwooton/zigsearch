const std = @import("std");
const expect = std.testing.expect;
const types = @import("../core/types.zig");
/// Reads the contents of a text file into a dynamically allocated buffer.
/// The caller is responsible for freeing the buffer.
pub fn readTextFile(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const buffer = try allocator.alloc(u8, file_size);

    const bytes_read = try file.readAll(buffer);
    if (bytes_read != file_size) {
        return error.FileReadError;
    }

    return buffer;
}

test "readTextFile" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const path = "./test_data/doc1.txt";

    const file_content = try readTextFile(allocator, path);
    defer allocator.free(file_content);

    const expected_content =
        \\Hello world leaders!
        \\How are you?
        \\Where are you from?
        \\What day is it?
        \\We are going to the candy store.
    ;

    try expect(std.mem.eql(u8, file_content, expected_content));
}

/// Loads a document from a file.
/// The caller is responsible for calling the deinit method on the document
/// when it is no longer needed.
pub fn loadDocument(allocator: std.mem.Allocator, path: []const u8) !types.Document {
    const file_content = try readTextFile(allocator, path);
    // allocate memory for the name of the document
    const name = try allocator.alloc(u8, path.len);
    // copy the path to the name
    @memcpy(name, path);
    // now create the document
    const document = types.Document.init(name, file_content, allocator);
    // return the document
    return document;
}

test "loadDocument" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const path = "./test_data/doc1.txt";

    const document = try loadDocument(allocator, path);
    defer document.deinit();

    const expected_name = "./test_data/doc1.txt";
    const expected_content =
        \\Hello world leaders!
        \\How are you?
        \\Where are you from?
        \\What day is it?
        \\We are going to the candy store.
    ;
    std.debug.print("Document name: {s}\n", .{document.name});
    try expect(std.mem.eql(u8, document.name, expected_name));
    try expect(std.mem.eql(u8, document.text, expected_content));
}
