// TODO: it should not read the .git folder
// TODO: If the initial path is file then just  count the lines for that.
//
const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

const FileStat = struct {
    ex: []const u8,
    path: []const u8,
};

const FilesStats = std.MultiArrayList(FileStat);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var files = FilesStats{};
    defer files.deinit(allocator);

    const dir = readArgs(allocator) catch {
        std.debug.panic("Failed to read args", .{});
    } orelse "";

    if (std.mem.eql(u8, dir, "")) {
        std.debug.panic("Path not provided", .{});
    }

    var lines: i64 = 0;

    try readDirRecursively(dir, allocator, &files);

    print("Files found: {d}\n", .{files.len});

    for (files.items(.path), files.items(.ex)) |path, ex| {
        lines += try readFileLines(path, allocator);

        print("{d}\r", .{lines});

        allocator.free(path);
        allocator.free(ex);
    }

    print("Number of lines {d}\n", .{lines});
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

fn readDirRecursively(dirPath: []const u8, allocator: std.mem.Allocator, files_stats: *FilesStats) !void {
    var currDir = try std.fs.cwd().openDir(dirPath, .{ .iterate = true });
    defer currDir.close();

    var iterator = currDir.iterate();

    while (try iterator.next()) |entry| {
        const file_name = std.fmt.allocPrint(allocator, "{s}/{s}", .{ dirPath, entry.name }) catch {
            // TODO: fix this later
            continue;
        };
        defer allocator.free(file_name);

        const stat = try std.fs.cwd().statFile(file_name);

        if (stat.kind == .directory) {
            try readDirRecursively(file_name, allocator, files_stats);
        } else if (stat.kind == .file) {
            const extension = std.fs.path.extension(file_name);

            const path = try allocator.dupe(u8, file_name);
            errdefer allocator.free(path);

            const ex = try allocator.dupe(u8, extension);
            errdefer allocator.free(ex);

            try files_stats.append(allocator, .{ .ex = ex, .path = path });
        } else {
            // TODO: handle this
            continue;
        }
    }
}

fn readFileLines(file_path: []const u8, allocator: std.mem.Allocator) !i64 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_size = (try file.stat()).size;

    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    var count: i64 = 0;

    while (file.reader().readUntilDelimiterOrEof(buffer, '\n') catch {
        return 0;
    }) |line| {
        _ = line;
        count += 1;
    }

    return count;
}

// const extension = std.fs.path.extension(file_path);
