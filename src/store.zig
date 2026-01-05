const std = @import("std");

pub const FileManager = struct {
    gpa: std.mem.Allocator,
    path: []const u8,
    file: std.fs.File,
    __cache: []u8 = undefined,
    __did_updated_cache: bool = false,
    pub fn exists(path: []const u8) bool {
        std.fs.accessAbsolute(path, .{
            .mode = .read_only,
        }) catch return false;
        return true;
    }

    pub fn init(
        allocator: std.mem.Allocator,
        path: []const u8,
        createContent: ?([]const u8),
    ) !*FileManager {
        var f = try allocator.create(FileManager);
        f.gpa = allocator;
        f.path = path;
        const __cache = try allocator.alloc(u8, 2);
        f.__cache = __cache;
        f.__did_updated_cache = false;
        if (!FileManager.exists(path)) {
            const fs = try std.fs.createFileAbsolute(path, .{
                .truncate = true,
                .read = true,
            });
            if (createContent) |c| {
                try f.cover(c);
            }
            f.file = fs;
            return f;
        }
        const fs = try std.fs.openFileAbsolute(path, .{
            .mode = .read_write,
        });
        f.__cache = __cache;
        f.__did_updated_cache = false;
        f.file = fs;
        return f;
    }

    pub fn deinit(this: *FileManager) void {
        this.file.close();
        this.gpa.free(this.__cache);
    }

    pub fn read(this: *FileManager) ![]const u8 {
        if (this.__did_updated_cache) {
            return this.__cache;
        }
        const size = try this.file.getEndPos();
        var buf: [1024]u8 = undefined;
        var r = this.file.reader(&buf);
        const content = try r.interface.readAlloc(this.gpa, size);
        this.gpa.free(this.__cache);
        this.__cache = content;
        this.__did_updated_cache = true;
        return this.__cache;
    }

    pub fn backup(this: *FileManager) !void {
        var buf: [128]u8 = undefined;
        const backupFile = try std.fmt.bufPrint(&buf, comptime "{s}.bak", .{this.path});
        if (!exists(backupFile)) {
            try std.fs.copyFileAbsolute(this.path, backupFile, .{});
            std.debug.print("backup /etc/hosts file to {s}\n", .{backupFile});
        }
    }

    pub fn cover(this: *FileManager, content: []const u8) !void {
        try this.file.seekTo(0);
        try this.file.writeAll(content);
        try this.file.setEndPos(content.len);
        this.__did_updated_cache = false;
    }

    pub fn append(this: *FileManager, content: []const u8) !void {
        const end = try this.file.getEndPos();
        try this.file.seekTo(end);
        try this.file.writeAll(content);
        try this.file.setEndPos(end + content.len);

        this.__did_updated_cache = false;
    }
};

const ZHOST_RC_ZON_NAME = ".zhostrc.zon";

pub const HostStore = struct {
    configHost: *FileManager,
    systemHost: *FileManager,
    gpa: std.mem.Allocator,
    pub fn init(gpa: std.mem.Allocator) !HostStore {
        const systemHostFile = try FileManager.init(gpa, switch (@import("builtin").os.tag) {
            .windows => "C:\\Windows\\System32\\drivers\\etc\\hosts",
            else => "/etc/hosts",
        }, null);
        try systemHostFile.backup();
        const home = try std.process.getEnvVarOwned(
            std.heap.page_allocator,
            "HOME",
        );

        defer std.heap.page_allocator.free(home);
        const configHost = try std.fs.path.join(
            std.heap.page_allocator,
            &.{
                home,
                ZHOST_RC_ZON_NAME,
            },
        );
        const configHostFile = try FileManager.init(
            gpa,
            configHost,
            \\.{
            \\  .hosts = .{
            \\      .{
            \\          .content = "www.demo.com 127.0.0.1",
            \\          .name = "demo",
            \\          .open = false,
            \\          .id = 1,
            \\      }
            \\  },
            \\}
            ,
        );

        return .{
            .gpa = gpa,
            .systemHost = systemHostFile,
            .configHost = configHostFile,
        };
    }
    fn deinit(this: *HostStore) void {
        this.systemHost.deinit();
        this.configHost.deinit();
        this.gpa.free(this.systemHost);
        this.gpa.free(this.configHost);
    }
};
