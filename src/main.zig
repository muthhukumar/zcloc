const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

pub fn main() !void {
    const result = try read_file_lines("./output.txt");

    print("num of lines in {}{}\n", .{ result[0], result[1] });
}

fn read_file_lines(file_path: []const u8) !struct { i64, u64 } {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size + 1);
    defer allocator.free(buffer);

    var count: i64 = 0;
    var chars: u64 = 0;

    while (try file.reader().readUntilDelimiterOrEof(buffer, '\n')) |line| {
        count += 1;
        chars += line.len;

        print("{s}\n", .{line});
    }

    return .{ count, chars };
}
