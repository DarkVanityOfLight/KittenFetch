const std = @import("std");
const testing = @import("std").testing;

const cat =
    \\ /|/|
    \\(. .) // 
    \\ |##\//
    \\ [w w]
;

const box_width = 6;
const cat_widht = 8;
// As string for less lines as code, more efficient if we do as int direct i think
const default_columns = "100";

// I hate string manipulations
pub fn create_box(allocator: std.mem.Allocator, name: *const []u8, box_wall_char: u8, box_floor_char: u8, box_space_char: u8) ![]const u8 {
    const name_length = if (box_width > name.*.len) box_width else name.*.len;
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

fn output(lines: [][]const u8, file: std.fs.File) !void {
    const writer = file.writer();
    for (lines) |line| {
        _ = try writer.write(line);
        _ = try writer.writeByte('\n');
    }
}

test "Test output function" {
    var lines = [_][]const u8{
        "Hello, ",
        "world!",
    };

    const tempFileName = "temp_test_file.txt";
    var tmp_dir = testing.tmpDir(.{});
    defer tmp_dir.cleanup();

    // Create a temporary file for testing
    var file = try tmp_dir.dir.createFile(tempFileName, .{ .read = true });
    defer file.close();

    // Call the function with the test data
    try output(&lines, file);

    const file2 = try tmp_dir.dir.openFile(tempFileName, .{});
    defer file2.close();

    // Read the content of the file and assert it's as expected
    const content = try file2.readToEndAlloc(testing.allocator, 1024);
    defer testing.allocator.free(content);

    try testing.expect(std.mem.eql(u8, content, "Hello, \nworld!\n"));
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const box_alloc = gpa.allocator();

    // Get the Terminal column size from tput
    // @zig-fmt off
    const res = try std.ChildProcess.exec(.{ .allocator = std.heap.page_allocator, .argv = &[_][]const u8{ "tput", "cols" } });
    // @zig-fmt on

    // Last character is a \n so slice it
    const cols: usize = std.fmt.parseInt(usize, res.stdout[0 .. res.stdout.len - 1], 10) catch 50;

    // So if we have less columns then cat width, we can't really display anything so we exit
    if (cols < cat_widht) {
        std.os.exit(0);
    }

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var hostname: [std.os.HOST_NAME_MAX]u8 = undefined;
    const name = try std.os.gethostname(&hostname);

    const box = try create_box(box_alloc, &name, '|', '=', ' ');
    defer box_alloc.free(box);

    try stdout.print(cat, .{});
    try stdout.print("\n", .{});
    try stdout.print("{s}", .{box});

    try bw.flush(); // don't forget to flush!
}
