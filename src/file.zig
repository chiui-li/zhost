const std = @import("std");

const Allocator = std.mem.Allocator;

//
// 读取文件
//
pub fn read(path: []const u8, allocator: Allocator) ![]u8 {
    var f: std.fs.File = undefined;
    if (!std.fs.path.isAbsolute(path)) {
        f = try std.fs.cwd().openFile(path, .{
            .mode = .read_only,
        });
    } else {
        f = try std.fs.openFileAbsolute(path, .{
            .mode = .read_only,
        });
    }

    defer f.close();
    const size = try f.getEndPos();
    const content = try allocator.alloc(u8, size);
    _ = try f.read(content);
    return content;
}

//
// 写入内容(覆盖)
//
pub fn write(path: []const u8, content: []const u8) !void {
    var f: std.fs.File = undefined;
    if (!std.fs.path.isAbsolute(path)) {
        f = try std.fs.cwd().createFile(path, .{
            .truncate = true,
        });
    } else {
        f = try std.fs.createFileAbsolute(path, .{
            .truncate = true,
        });
    }

    defer f.close();
    _ = try f.write(content);
}

pub fn access(path: []const u8) bool {
    const has = std.fs.accessAbsolute(path, .{ .mode = .read_only });
    if (has) |_| {
        return true;
    } else |_| {
        const hasRelative = std.fs.cwd().access(path, .{ .mode = .read_only });
        if (hasRelative) |_| {
            return true;
        } else |_| {
            return false;
        }
    }
}
