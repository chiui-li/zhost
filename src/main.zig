//!
//! Part of the Zap examples.
//!
//! Build me with `zig build     routes`.
//! Run   me with `zig build run-routes`.
//!
const std = @import("std");
const zap = @import("zap");
const indexHtml = @embedFile("./dist/index.html");
const indexJs = @embedFile("./dist/index.js");
const indexCss = @embedFile("./dist/index.css");
const ZhostRoot = @import("./root.zig");
// NOTE: this is a super simplified example, just using a hashmap to map
// from HTTP path to request function.
fn dispatch_routes(r: zap.Request) !void {
    // dispatch
    //
    if (r.path) |the_path| {
        if (routes.get(the_path)) |foo| {
            try r.setHeader("Access-Control-Allow-Origin", "*");
            try r.setHeader("Access-Control-Request-Method", "*");
            try r.setHeader("Access-Control-Request-Headers", "*");
            try foo(r);
            return;
        }
    }
    try r.sendBody(indexHtml);
}

fn webSiteAssets(r: zap.Request) !void {
    if (r.path) |path| {
        if (std.mem.eql(u8, path, "/")) {
            try r.setHeader("content-type", "text/html; charset=utf-8");
            try r.sendBody(indexHtml);
        }
        if (std.mem.eql(u8, path, "/index.js")) {
            try r.setHeader("content-type", "text/javascript; charset=utf-8");
            try r.sendBody(indexJs);
        }
        if (std.mem.eql(u8, path, "/index.css")) {
            try r.setHeader("content-type", "text/css; charset=utf-8");
            try r.sendBody(indexCss);
        }
    }
    try r.sendBody(indexHtml);
}

fn getHostList(r: zap.Request) !void {
    if (r.path) |_| {
        const content = try hostManager.getHostsConfig();
        try r.setHeader("content-type", "text/zon; charset=utf-8");
        try r.sendBody(content);
    }
}

fn updateHost(r: zap.Request) !void {
    if (r.path) |_| {
        const bodySentinel = try std.fmt.allocPrintSentinel(std.heap.page_allocator, "{s}", .{r.body.?}, 0);
        defer std.heap.page_allocator.free(bodySentinel);
        var u = try std.zon.parse.fromSlice(
            ZhostRoot.HostConfig,
            std.heap.page_allocator,
            bodySentinel,
            null,
            .{},
        );
        defer std.zon.parse.free(std.heap.page_allocator, u);
        try hostManager.updateHostConfig(&u);
        r.setStatus(.ok);
        try r.sendBody(".{ .success = true, }");
    }
}

fn getSysHost(r: zap.Request) !void {
    if (r.path) |_| {
        const sys = try hostManager.getSystemHost();
        var w = std.io.Writer.Allocating.init(std.heap.page_allocator);
        try std.zon.stringify.serialize(.{
            .open = false,
            .name = "系统 host",
            .content = sys,
            .id = 0,
        }, .{}, &w.writer);
        try r.setHeader("content-type", "text/zon; charset=utf-8");
        try r.sendBody(w.written());
    }
}

fn addNewHost(r: zap.Request) !void {
    if (r.path) |_| {
        const bodySentinel = try std.fmt.allocPrintSentinel(std.heap.page_allocator, "{s}", .{r.body.?}, 0);
        defer std.heap.page_allocator.free(bodySentinel);
        var u = try std.zon.parse.fromSlice(
            ZhostRoot.HostConfig,
            std.heap.page_allocator,
            bodySentinel,
            null,
            .{},
        );
        defer std.zon.parse.free(std.heap.page_allocator, u);
        try hostManager.addHostConfig(&u);
        r.setStatus(.ok);
        try r.sendBody(".{ .success = true, }");
    }
}

fn setup_routes(a: std.mem.Allocator) !void {
    routes = std.StringHashMap(zap.HttpRequestFn).init(a);
    try routes.put("/", webSiteAssets);
    try routes.put("/index.js", webSiteAssets);
    try routes.put("/index.css", webSiteAssets);
    //
    // api
    //
    try routes.put("/api/getHostList", getHostList);
    try routes.put("/api/updateHost", updateHost);
    try routes.put("/api/sysHost", getSysHost);
    try routes.put("/api/addNewHost", addNewHost);
}

var routes: std.StringHashMap(zap.HttpRequestFn) = undefined;

var zhost: *ZhostRoot.Zhost = undefined;

var hostManager: ZhostRoot.HostManager = undefined;

pub fn main() !void {
    // zhost = try ZhostRoot.Zhost.initByZon(std.heap.page_allocator);
    hostManager = try ZhostRoot.HostManager.init(std.heap.page_allocator);
    try setup_routes(std.heap.page_allocator);
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = dispatch_routes,
        .log = true,
    });

    try listener.listen();
    std.debug.print("Listening on http://127.0.0.1:3000\n", .{});
    zap.start(.{
        .threads = 1,
        .workers = 1,
    });
}
