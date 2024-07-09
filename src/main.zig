const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const arg = try readArgs(allocator);

    if (arg.?.len == 0) {
        // TODO: Stop the program
        return;
    }

    const dir = arg.?;

    var currDir = try std.fs.cwd().openDir(dir, .{ .iterate = true });
    defer currDir.close();

    var iterator = currDir.iterate();

    while (try iterator.next()) |entry| {
        const file_name = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ dir, entry.name });
        defer allocator.free(file_name);

        const stat = try std.fs.cwd().statFile(file_name);

        if (stat.kind != .file) {
            print("'{s}' is not a file so ignoring it.\n", .{entry.name});
            continue;
        }

        const count = try readFileLines(file_name, allocator);

        print("{s} = {d} Lines, {d} Characters\n", .{ entry.name, count[0], count[1] });
        print("\n", .{});
    }
}

fn readArgs(allocator: std.mem.Allocator) !?[]const u8 {
    var iterator = try std.process.argsWithAllocator(allocator);
    defer iterator.deinit();

    _ = iterator.next();

    if (iterator.next()) |currPath| {
        return currPath;
    }

    return undefined;
}

fn readDirRecursively(dirPath: []const u8, allocator: std.mem.Allocator, lines: *i64) !void {}

fn readFileLines(file_path: []const u8, allocator: std.mem.Allocator) !struct { i64, u64 } {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var count: i64 = 0;
    var chars: u64 = 0;

    while (try file.reader().readUntilDelimiterOrEof(buffer, '\n')) |line| {
        count += 1;
        chars += line.len;
    }

    return .{ count, chars };
}
