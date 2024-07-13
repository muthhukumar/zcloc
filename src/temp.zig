const std = @import("std");

const FileStat = struct {
    ex: []const u8,
    path: []const u8,
};

const FilesStatList = std.MultiArrayList(FileStat);
const FilesStatHashMap = std.StringArrayHashMap(FilesStatList);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var files_stat_hashmap = FilesStatHashMap.init(allocator);
    defer files_stat_hashmap.deinit();

    try add_file(&files_stat_hashmap, allocator);
    try add_file(&files_stat_hashmap, allocator);
    try add_file(&files_stat_hashmap, allocator);
    try add_file(&files_stat_hashmap, allocator);
    try add_file(&files_stat_hashmap, allocator);

    var iter = files_stat_hashmap.iterator();

    while (iter.next()) |item| {
        defer item.value_ptr.deinit(allocator);
        // std.debug.print("extension: {s}\n", .{item.key_ptr.*});

        for (item.value_ptr.items(.ex), item.value_ptr.items(.path)) |ex, path| {
            std.debug.print("[{s}].{s}\n", .{ ex, path });
        }
    }
}

fn add_file(file_stats: *FilesStatHashMap, allocator: std.mem.Allocator) !void {
    const result = file_stats.getEntry(".js");

    if (result) |arr| {
        try arr.value_ptr.*.append(allocator, .{ .path = "src/index.js", .ex = ".js" });
    } else {
        const new_list = FilesStatList{};

        try file_stats.put(".js", new_list);
    }
}
