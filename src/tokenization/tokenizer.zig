const std = @import("std");
const expect = std.testing.expect;

pub fn tokenizeString(allocator: std.mem.Allocator, text: []const u8) !std.ArrayList([]const u8) {
    // initialize the array list of tokens
    var tokens = std.ArrayList([]const u8).init(allocator);
    // tokenize the text on whitespace
    var it = std.mem.tokenizeAny(u8, text, " \n\t\r");
    // add each token to the array list; make sure to allocate space for it
    while (it.next()) |token| {
        // allocate space for the token
        const token_alloc = try allocator.alloc(u8, token.len);
        // copy the token to the allocated space
        @memcpy(token_alloc, token);
        // add the token to the array list
        try tokens.append(token_alloc);
    }
    // return the array list of tokens
    return tokens;
}

test "tokenizeString" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const text =
        \\Hello world leaders!
        \\How are you?
        \\Where are you from?
        \\What day is it?
        \\We are going to the candy store.
    ;

    const expected_tokens = [_][]const u8{
        "Hello", "world", "leaders!",
        "How",   "are",   "you?",
        "Where", "are",   "you",
        "from?", "What",  "day",
        "is",    "it?",   "We",
        "are",   "going", "to",
        "the",   "candy", "store.",
    };

    const tokens = try tokenizeString(allocator, text);

    for (0.., tokens.items) |i, token| {
        try expect(std.mem.eql(u8, token, expected_tokens[i]));
    }

    // deallocate the tokens
    for (tokens.items) |token| {
        allocator.free(token);
    }
    // deallocate the array list
    tokens.deinit();
}
