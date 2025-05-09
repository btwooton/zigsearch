const std = @import("std");
const expect = std.testing.expect;

/// Helper function to check if a character is punctuation
fn is_punctuation(c: u8) bool {
    return (c >= 33 and c <= 47) or (c >= 58 and c <= 64) or
        (c >= 91 and c <= 96) or (c >= 123 and c <= 126);
}

/// Declare custom Iterator type for getting lowercased and punctuation-free tokens
/// from an existing TokenIterator
pub const CleanTokenIterator = struct {
    it: std.mem.TokenIterator(u8, std.mem.DelimiterType.any),
    allocator: std.mem.Allocator,
    token_store: std.ArrayList([]const u8),

    pub fn init(
        allocator: std.mem.Allocator,
        it: std.mem.TokenIterator(u8, std.mem.DelimiterType.any),
    ) CleanTokenIterator {
        return CleanTokenIterator{
            .it = it,
            .allocator = allocator,
            .token_store = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn next(self: *CleanTokenIterator) !?[]const u8 {
        // get the next token from the underlying iterator
        const token = self.it.next();

        if (token) |t| {

            // get a mutable slice of the token
            var token_mut = try self.allocator.alloc(u8, t.len);
            // copy the token to the mutable slice
            @memcpy(token_mut, t);
            // save the token to the token store for later deallocation
            try self.token_store.append(token_mut);
            // convert the token to lowercase
            for (0.., token_mut) |i, c| {
                if (c >= 'A' and c <= 'Z') {
                    token_mut[i] = c + 32; // convert to lowercase
                }
            }
            // strip any punctuation from the token
            var token_end = token_mut.len;
            while (token_end > 0 and is_punctuation(token_mut[token_end - 1])) {
                token_end -= 1;
            }
            // return the token without punctuation
            return token_mut[0..token_end];
        } else {
            return null;
        }
    }

    pub fn reset(self: *CleanTokenIterator) void {
        // reset the underlying iterator
        self.it.reset();
        // deallocate all tokens in the token store
        for (self.token_store.items) |token| {
            self.allocator.free(token);
        }
    }

    pub fn deinit(self: *CleanTokenIterator) void {
        // deallocate all tokens in the token store
        for (self.token_store.items) |token| {
            self.allocator.free(token);
        }
        // deinitialize the token store
        self.token_store.deinit();
    }
};

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

pub fn tokenizeStringIterator(
    text: []const u8,
) std.mem.TokenIterator(u8, std.mem.DelimiterType.any) {
    // tokenize the text on whitespace
    const it = std.mem.tokenizeAny(u8, text, " \n\t\r");
    // return the iterator
    return it;
}

pub fn tokenizeStringIteratorClean(
    text: []const u8,
    allocator: std.mem.Allocator,
) CleanTokenIterator {
    // tokenize the text on whitespace
    const it = tokenizeStringIterator(text);
    // create a new CleanTokenIterator
    const clean_it = CleanTokenIterator.init(allocator, it);
    // return the iterator
    return clean_it;
}

test "tokenizeStringIteratorClean" {
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
        "hello", "world", "leaders",
        "how",   "are",   "you",
        "where", "are",   "you",
        "from",  "what",  "day",
        "is",    "it",    "we",
        "are",   "going", "to",
        "the",   "candy", "store",
    };
    // tokenize the text using the CleanTokenIterator
    var it = tokenizeStringIteratorClean(text, allocator);
    // make sure that we de init the iterator
    defer it.deinit();
    for (0..expected_tokens.len) |i| {
        // get the next token from the iterator
        const token = try it.next();
        if (token) |t| {
            // check if the token is equal to the expected token
            try expect(std.mem.eql(u8, t, expected_tokens[i]));
        }
    }
}
