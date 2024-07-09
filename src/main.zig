const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("./output.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);

    print("{}", .{file_size});

    defer allocator.free(buffer);

    var count: i64 = 0;
    var len: usize = 0;

    while (try file.reader().readUntilDelimiterOrEof(buffer, '\n')) |line| {
        print("{s}\n", .{line});
        len += line.len;
        count += 1;
    }

    print("number of lines = {}\n length = {}\n", .{ count, len });
}

fn count_lines(str: []const u8) i64 {
    var count: i64 = 0;

    var idx: usize = 0;

    while (idx < str.len) : (idx += 1) {
        const val = str[idx];

        if (val == '\n') {
            count += 1;
        }
    }

    return count;
}
test "simple test" {}
