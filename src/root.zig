//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const os = @import("builtin").target.os.tag;
const print = std.debug.print;
const file = @import("./file.zig");

var debugAllocator = std.heap.DebugAllocator(.{}).init;

pub fn bufferedPrint() !void {
    defer _ = debugAllocator.deinit();
    const gpa = debugAllocator.allocator();
    // const gpa = std.heap.page_allocator;
    const s = std.time.milliTimestamp();
    std.debug.print("time start: {d}\n", .{s});
    var zhost = try Zhost.init(gpa);
    defer zhost.deinit();
    var host = HostConfig{
        .content = "hello world",
        .name = "test",
        .id = 0,
        .open = false,
    };
    for (0..1000) |i| {
        host.id = i;
        try zhost.addHostConfig(&host);
    }

    // try zhost.toZon();
    try zhost.delHostConfig(88);
    try zhost.delHostConfig(500);
    // try zhost.toZon();
    host.content = "hello world2hashgdhajskdgsahjkdgsakdgasdoqwgowquytwquyetwquyetwquetqweiuwqyteqwuetwqueywqteiuyqwevgcfsghxfaskadbvxhvkskfsa";
    try zhost.updateHostConfig(678, &host);
    const c = std.time.milliTimestamp();
    std.debug.print("time end: {d}\n", .{c});

    std.debug.print("time all: {d}\n", .{c - s});
    try zhost.toZon();
}

pub const HostConfig = struct {
    id: usize,
    name: []const u8,
    content: []const u8,
    open: bool = false,
    fn toOwned(this: @This(), gap: std.mem.Allocator) !*HostConfig {
        const host = try gap.create(HostConfig);
        host.content = try gap.dupe(u8, this.content);
        host.name = try gap.dupe(u8, this.name);
        host.id = this.id;
        host.open = this.open;
        return host;
    }

    pub fn setContent(this: *HostConfig, c: []const u8, gpa: std.mem.Allocator) void {
        gpa.free(this.content);
        this.content = c;
    }

    pub fn setName(this: *HostConfig, n: []const u8, gpa: std.mem.Allocator) void {
        gpa.free(this.name);
        this.content = n;
    }

    fn deinit(this: *HostConfig, gap: std.mem.Allocator) void {
        gap.free(this.content);
        gap.free(this.name);
        gap.destroy(this);
    }
};

pub const Zhost = struct {
    gpa: std.mem.Allocator = std.heap.page_allocator,

    hosts: std.ArrayList(*HostConfig),

    pub fn init(gpa: std.mem.Allocator) !Zhost {
        const hosts = try std.ArrayList(*HostConfig).initCapacity(gpa, 10);
        return Zhost{
            .hosts = hosts,
            .gpa = gpa,
        };
    }

    pub fn addHostConfig(this: *Zhost, host: *HostConfig) !void {
        const owned = try host.toOwned(this.gpa);
        try this.hosts.append(this.gpa, owned);
    }

    pub fn updateHostConfig(this: *Zhost, id: usize, newHostConfig: *HostConfig) !void {
        const owned = try newHostConfig.toOwned(this.gpa);
        var i: usize = 0;

        for (this.hosts.items) |host| {
            if (id == host.id) {
                host.deinit(this.gpa);
                break;
            }
            i += 1;
        }

        if (i < this.hosts.items.len) {
            this.hosts.items[i] = owned;
        }
    }

    pub fn delHostConfig(this: *Zhost, id: usize) !void {
        var i: usize = 0;
        for (this.hosts.items) |host| {
            if (host.id == id) {
                host.deinit(this.gpa);
                break;
            }
            i += 1;
        }

        _ = this.hosts.orderedRemove(i);
    }

    pub fn toZon(this: @This()) !void {
        var content = std.io.Writer.Allocating.init(this.gpa);
        defer content.deinit();
        const w = &content.writer;
        try std.zon.stringify.serialize(this.hosts.items, .{ .whitespace = true }, w);
        std.debug.print("{s}\n", .{content.written()});
    }

    pub fn deinit(this: *Zhost) void {
        for (this.hosts.items) |host| {
            host.deinit(this.gpa);
        }
        this.hosts.deinit(this.gpa);
    }
};

const ZHOST_RC_ZON = ".zhostrc.zon";

const ZhostZon = struct {
    hosts: []*HostConfig,
    pub fn toZhost(this: @This(), gpa: std.mem.Allocator) !*Zhost {
        const zhost = try gpa.create(Zhost);
        zhost.hosts = try std.ArrayList(*HostConfig).initCapacity(gpa, this.hosts.len + 10);
        for (this.hosts) |value| {
            try zhost.addHostConfig(value);
        }
        return zhost;
    }
};

pub fn zhostCreateByZon(gpa: std.mem.Allocator) !*Zhost {
    var env = try std.process.getEnvMap(gpa);
    const home = env.get("HOME") orelse "unknown";
    defer env.deinit();
    const zonPath = try std.fs.path.join(gpa, &.{ home, ZHOST_RC_ZON });
    defer gpa.free(zonPath);
    const hasZon = file.access(zonPath);
    if (hasZon) {
        const zhostRC = try file.read(zonPath, gpa);
        defer gpa.free(zhostRC);

        const zhostRCSentinel = try std.fmt.allocPrintSentinel(gpa, "{s}", .{zhostRC}, 0);
        defer gpa.free(zhostRCSentinel);

        const zhostItems = try std.zon.parse.fromSlice(ZhostZon, gpa, zhostRCSentinel, null, .{
            .ignore_unknown_fields = true,
        });

        defer std.zon.parse.free(gpa, zhostItems);
        return zhostItems.toZhost(gpa);
    } else {
        try file.write(
            zonPath,
            \\.{
            \\  .hosts = .{
            \\      .{
            \\          .content = "www.demo.com 127.0.0.1\n",
            \\          .name = "demo",
            \\          .open = false,
            \\          .id = 1,
            \\      }
            \\  },
            \\}
            \\
            ,
        );
        return try zhostCreateByZon(gpa);
    }
    //
}

test "test zhostConfig" {
    const gpa = std.testing.allocator;
    const v = try zhostCreateByZon(gpa);
    try v.toZon();
    defer v.deinit();
}
