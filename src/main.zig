const std = @import("std");

const cat =
    \\ /|/|
    \\(. .) // 
    \\ |##\//
    \\ [w w]
;

const cat_width = 6;

// I hate string manipulations
pub fn create_box(allocator: std.mem.Allocator, name: *const []u8, box_wall_char: u8, box_floor_char: u8, box_space_char: u8) ![]const u8 {
    const name_length = if (cat_width > name.*.len) cat_width else name.*.len;
    const line_lenght = 1 + name_length + 1 + 1;
    var buffer = try allocator.alloc(u8, line_lenght * 3);

    buffer[0] = box_wall_char;

    var i: usize = 1;
    for (name_length) |_| {
        buffer[i] = box_floor_char;
        i = i + 1;
    }

    buffer[i] = box_wall_char;
    buffer[i + 1] = '\n';

    buffer[i + 2] = box_wall_char;
    i = i + 3;

    const pad = name_length - name.*.len;
    const pad_left = pad / 2;
    const pad_right = pad - pad_left;

    for (pad_left) |_| {
        buffer[i] = box_space_char;
        i = i + 1;
    }

    for (name.*) |character| {
        buffer[i] = character;
        i = i + 1;
    }

    for (pad_right) |_| {
        buffer[i] = box_space_char;
        i = i + 1;
    }

    buffer[i] = box_wall_char;
    buffer[i + 1] = '\n';

    buffer[i + 2] = box_wall_char;
    i = i + 3;

    for (name_length) |_| {
        buffer[i] = box_floor_char;
        i = i + 1;
    }

    buffer[i] = box_wall_char;
    buffer[i + 1] = '\n';

    return buffer;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const box_alloc = gpa.allocator();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var hostname: [std.os.HOST_NAME_MAX]u8 = undefined;
    const name = try std.os.gethostname(&hostname);

    const box = try create_box(box_alloc, &name);
    defer box_alloc.free(box);

    try stdout.print(cat, .{});
    try stdout.print("\n", .{});
    try stdout.print("{s}", .{box});

    try bw.flush(); // don't forget to flush!
}
