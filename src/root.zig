//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const os = @import("builtin").target.os.tag;
const print = std.debug.print;
const file = @import("./file.zig");

var debugAllocator = std.heap.DebugAllocator(.{}).init;

pub const ZhostPATH = struct {
    const hostsPath = "./hosts";
    const hostsBakPath = "./hosts.bak";
    var zhostRC: ?[]u8 = null;
    const ZHOST_RC_ZON_NAME = ".zhostrc.zon";
    fn getZhostRcZon() ![]u8 {
        if (ZhostPATH.zhostRC) |v| {
            return v;
        }
        const home = try std.process.getEnvVarOwned(std.heap.page_allocator, "HOME");
        defer std.heap.page_allocator.free(home);
        ZhostPATH.zhostRC = try std.fs.path.join(std.heap.page_allocator, &.{ home, ZhostPATH.ZHOST_RC_ZON_NAME });
        return ZhostPATH.zhostRC.?;
    }
};

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

    pub fn initByZon(gpa: std.mem.Allocator) !*Zhost {
        const zonPath = try ZhostPATH.getZhostRcZon();
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
                \\          .content = "127.0.0.1  demo.host.com\n",
                \\          .name = "host-demo",
                \\          .open = true,
                \\          .id = 1,
                \\      }
                \\  },
                \\}
                ,
            );
            return try initByZon(gpa);
        }
        //
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
        var f = try file.writer(try ZhostPATH.getZhostRcZon());
        defer f.close();
        var buf: [1024]u8 = undefined;
        var w = f.writer(&buf);
        try std.zon.stringify.serialize(.{
            .hosts = this.hosts.items,
        }, .{ .whitespace = true }, &w.interface);
    }

    pub fn toHost(this: @This()) !void {
        if (file.access(ZhostPATH.hostsBakPath)) {
            var buffer: [1024]u8 = undefined;
            const hostsFile = try file.writer(ZhostPATH.hostsPath);
            var w = hostsFile.writer(&buffer);
            _ = try w.interface.write(
                \\##
                \\# Host Database
                \\#
                \\# localhost is used to configure the loopback interface
                \\# when the system is booting.  Do not change this entry.
                \\##
                \\127.0.0.1       localhost
                \\255.255.255.255 broadcasthost
                \\::1             localhost
                ,
            );
            var hostConfigName: [512]u8 = undefined;
            for (this.hosts.items) |item| {
                if (item.open) {
                    const name = try std.fmt.bufPrint(&hostConfigName,
                        \\ 
                        \\
                        \\####### {s} #######
                        \\
                        \\
                    , .{item.name});
                    try w.interface.writeAll(name);

                    try w.interface.writeAll(item.content);
                }
            }
            try w.interface.flush();
        } else {
            try file.backupFile(ZhostPATH.hostsPath);
            try this.toHost();
        }
    }

    pub fn deinit(this: *Zhost) void {
        for (this.hosts.items) |host| {
            host.deinit(this.gpa);
        }
        this.hosts.deinit(this.gpa);
        this.gpa.destroy(this);
    }
};

const ZhostZon = struct {
    hosts: []*HostConfig,
    pub fn toZhost(this: @This(), gpa: std.mem.Allocator) !*Zhost {
        const zhost = try gpa.create(Zhost);
        zhost.gpa = gpa;
        zhost.hosts = try std.ArrayList(*HostConfig).initCapacity(gpa, this.hosts.len + 10);
        for (this.hosts) |value| {
            try zhost.addHostConfig(value);
        }
        return zhost;
    }
};

pub fn bufferedPrint() !void {
    defer _ = debugAllocator.deinit();
    const gpa = debugAllocator.allocator();
    const v = try Zhost.initByZon(gpa);
    defer v.deinit();
    try v.toZon();
    try v.toHost();
    var content: [1024]u8 = undefined;
    var name: [50]u8 = undefined;
    for (2..100) |i| {
        std.crypto.random.bytes(&content);
        std.crypto.random.bytes(&name);
        var c = HostConfig{
            .id = i,
            .open = true,
            .content = &content,
            .name = &name,
        };
        try v.addHostConfig(&c);
        try v.toHost();
        std.Thread.sleep(1000 * std.time.ns_per_ms);
    }
}
