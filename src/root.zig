const std = @import("std");
const os = @import("builtin").target.os.tag;
const print = std.debug.print;
const Store = @import("./store.zig");

var debugAllocator = std.heap.DebugAllocator(.{}).init;

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

const ZhostZon = struct {
    hosts: []*HostConfig,
};

pub const HostManager = struct {
    store: Store.HostStore,
    gpa: std.mem.Allocator,
    hosts: std.ArrayList(*HostConfig),
    //
    //
    //
    pub fn init(gpa: std.mem.Allocator) !HostManager {
        const store = try Store.HostStore.init(gpa);
        var configHost = store.configHost;
        const content = try configHost.read();
        const contentSentinel = try std.fmt.allocPrintSentinel(gpa, "{s}", .{content}, 0);
        const zon = try std.zon.parse.fromSlice(ZhostZon, gpa, contentSentinel, null, .{});
        var hosts = try std.ArrayList(*HostConfig).initCapacity(gpa, 10);
        for (zon.hosts) |v| {
            const host = try v.toOwned(gpa);
            try hosts.append(gpa, host);
        }
        return HostManager{
            .store = store,
            .gpa = gpa,
            .hosts = hosts,
        };
    }

    pub fn deinit(this: *HostManager) void {
        this.store.deinit();
    }

    pub fn addHostConfig(this: *HostManager, host: *HostConfig) !void {
        const hostOwned = try host.toOwned(this.gpa);
        try this.hosts.append(this.gpa, hostOwned);
        try this.saveToHostsConfig();
        if (host.open) {
            try this.saveToSystemHost();
        }
    }

    pub fn removeHostConfig(this: *HostManager, host: *HostConfig) !void {
        var index: usize = 0;
        for (this.hosts.items) |v| {
            if (v.id == host.id) {
                try this.hosts.remove(index);
                return;
            }
            index += 1;
        }
        try this.saveToHostsConfig();
    }

    pub fn updateHostConfig(this: *HostManager, host: *HostConfig) !void {
        var index: usize = 0;
        const w = try host.toOwned(this.gpa);
        var oldIsOpen: bool = false;
        for (this.hosts.items) |v| {
            if (v.id == w.id) {
                oldIsOpen = v.open;
                v.deinit(this.gpa);
                break;
            }
            index += 1;
        }
        if (index < this.hosts.items.len) {
            this.hosts.items[index] = w;
            try this.saveToHostsConfig();
            if (w.open) {
                try this.saveToSystemHost();
            } else if (!w.open and oldIsOpen) {
                try this.saveToSystemHost();
            }
        }
    }

    pub fn saveToHostsConfig(this: *HostManager) !void {
        var s = std.io.Writer.Allocating.init(this.gpa);
        try std.zon.stringify.serialize(.{
            .hosts = this.hosts.items,
        }, .{}, &s.writer);
        try this.store.configHost.cover(s.written());
    }

    pub fn saveToSystemHost(this: *HostManager) !void {
        try this.store.systemHost.cover(
            \\##
            \\# Host Database
            \\#
            \\# localhost is used to configure the loopback interface
            \\# when the system is booting.  Do not change this entry.
            \\##
            \\127.0.0.1       localhost
            \\255.255.255.255 broadcasthost
            \\::1             localhost
            \\
        );
        for (this.hosts.items) |host| {
            if (host.open) {
                const content = try std.fmt.allocPrint(
                    this.gpa,
                    \\
                    \\####### {s} #######
                    \\{s}
                    \\
                    \\
                ,
                    .{
                        host.name,
                        host.content,
                    },
                );
                try this.store.systemHost.append(content);
            }
        }
    }

    pub fn getHostsConfig(this: *HostManager) ![]const u8 {
        return try this.store.configHost.read();
    }

    pub fn setHostsConfig(this: *HostManager, content: []const u8) ![]const u8 {
        return try this.store.configHost.write(content);
    }

    pub fn getSystemHost(this: *HostManager) ![]const u8 {
        return try this.store.systemHost.read();
    }
};
