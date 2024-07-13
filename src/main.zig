// TODO: it should not read the .git folder
// TODO: If the initial path is file then just  count the lines for that.
// TODO: Limit the file size we allocate for a file. Because someone might use it to exploit it.

const std = @import("std");
const print = std.debug.print;
const parseInt = std.fmt.parseInt;

const FileStat = struct {
    ex: []const u8,
    path: []const u8,
};

const FilesStatList = std.MultiArrayList(FileStat);
const FilesStatHashMap = std.StringArrayHashMap(FilesStatList);

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    defer arena.deinit();
    const allocator = arena.allocator();

    var files_stat_hashmap = FilesStatHashMap.init(allocator);
    defer files_stat_hashmap.deinit();

    const dir = readArgs(allocator) catch {
        std.debug.panic("Failed to read args", .{});
    } orelse "";

    if (std.mem.eql(u8, dir, "")) {
        std.debug.panic("Path not provided", .{});
    }

    var lines: i64 = 0;
    var files: usize = 0;

    try readDirRecursively(dir, allocator, &files_stat_hashmap);

    var iterator = files_stat_hashmap.iterator();

    while (iterator.next()) |iter| {
        files += iter.value_ptr.len;

        for (iter.value_ptr.items(.ex), iter.value_ptr.items(.path)) |ex, path| {
            // _ = ex;
            std.debug.print("{s} | {s}\n", .{ ex, path });

            lines += try readFileLines(path, allocator);
            print("Lines: {d}\r", .{lines});
        }
    }

    print("Scanned files: {d}\n", .{files});
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

fn readDirRecursively(dirPath: []const u8, allocator: std.mem.Allocator, files_stats_hashmap: *FilesStatHashMap) !void {
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

        switch (stat.kind) {
            .directory => try readDirRecursively(file_name, allocator, files_stats_hashmap),
            .file => {
                const extension = std.fs.path.extension(file_name);

                // Ignore the files that don't have extensions
                if (std.mem.eql(u8, extension, "")) continue;

                const file_name_cpy = try allocator.dupe(u8, file_name);
                errdefer allocator.free(file_name_cpy);

                try add_file_to_hashmap(allocator, files_stats_hashmap, extension, .{ .ex = extension, .path = file_name_cpy });
            },
            else => {
                continue;
            },
        }
    }
}

fn add_file_to_hashmap(allocator: std.mem.Allocator, file_stats_hashmap: *FilesStatHashMap, extension: []const u8, file_stat: FileStat) !void {
    const ex = try allocator.dupe(u8, extension);

    const entry = file_stats_hashmap.getPtr(ex);

    if (entry) |e| {
        try e.*.append(allocator, file_stat);
    } else {
        try file_stats_hashmap.put(ex, FilesStatList{});
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
