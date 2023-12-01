const std = @import("std");
const testing = @import("std").testing;

const cat = [_][]const u8{
    \\ /|/|    
    ,
    \\(. .) // 
    ,
    \\ |##\//  
    ,
    \\ [w w]   
};

const box_width = 6;
const cat_widht = 9;
const expand_width = 0;

const cat_height = 4;
const box_height = 3;
const expand_height = 0;

const space_between = 5;

// Prepare what we can at comptime
// Copy the cat to it and
comptime {
    var renderBuffer: [cat_height + box_height + expand_height][]u8 = undefined;
    _ = renderBuffer;
}

// I hate string manipulations
pub fn create_box(allocator: std.mem.Allocator, name: []const u8, box_wall_char: u8, box_floor_char: u8, box_space_char: u8) ![]const u8 {
    const name_length = if (box_width > name.len) box_width else name.len;
    const line_lenght = 1 + name_length + 1 + 1;
    var buffer = try allocator.alloc(u8, line_lenght * 3);

    buffer[0] = box_wall_char;

    var i: usize = 1;
    for (name_length) |_| {
        buffer[i] = box_floor_char;
        i = i + 1;
    }

    buffer[i] = box_wall_char;
    buffer[i + 1] = ' ';

    buffer[i + 2] = box_wall_char;
    i = i + 3;

    const pad = name_length - name.len;
    const pad_left = pad / 2;
    const pad_right = pad - pad_left;

    for (pad_left) |_| {
        buffer[i] = box_space_char;
        i = i + 1;
    }

    for (name) |character| {
        buffer[i] = character;
        i = i + 1;
    }

    for (pad_right) |_| {
        buffer[i] = box_space_char;
        i = i + 1;
    }

    buffer[i] = box_wall_char;
    buffer[i + 1] = ' ';

    buffer[i + 2] = box_wall_char;
    i = i + 3;

    for (name_length) |_| {
        buffer[i] = box_floor_char;
        i = i + 1;
    }

    buffer[i] = box_wall_char;
    buffer[i + 1] = ' ';

    return buffer;
}

// Render a cat into the provided buffer
fn renderCat(allocator: std.mem.Allocator, buffer: *[cat_height + box_height + expand_height][]const u8, hostname: []const u8, username: []const u8) !void {

    // Create space_between spaces
    var spaces: [space_between]u8 = undefined;
    for (0..space_between) |i| {
        spaces[i] = ' ';
    }

    // Line 0 is just the cat
    buffer[0] = cat[0];

    // Line 1 contains the username@hostname
    var line1: []u8 = undefined;
    line1 = try allocator.alloc(u8, 1 + cat_widht + space_between + hostname.len + 1 + username.len + 1);

    std.mem.copy(u8, line1, cat[1]);
    std.mem.copy(u8, line1[cat_widht..line1.len], &spaces);
    line1[cat_widht + space_between] = ' ';
    std.mem.copy(u8, line1[cat_widht + space_between + 1 .. line1.len], username);

    line1[cat_widht + space_between + username.len + 1] = '@';
    std.mem.copy(u8, line1[cat_widht + space_between + username.len + 1 + 1 .. line1.len], hostname);

    line1[line1.len - 1] = ' ';

    buffer[1] = line1;

    // Line 2 contains the top of the second box

    var boxlength: usize = 1 + hostname.len + 1 + username.len + 1;

    if (boxlength < 5) {
        boxlength = 5;
    }

    boxlength = boxlength + ((boxlength - 5) % 3);

    var line2: []u8 = undefined;
    line2 = try allocator.alloc(u8, cat_widht + space_between + boxlength);

    std.mem.copy(u8, line2, cat[2]);
    std.mem.copy(u8, line2[cat_widht..line2.len], &spaces);
    line2[cat_widht + space_between] = '|';
    for (cat_widht + space_between + 1..line2.len) |i| {
        line2[i] = '=';
    }

    line2[line2.len - 1] = '|';
    buffer[2] = line2;

    //Line 3 Contains the circles
    //TODO: Unicode/Ascii????? can't display ⚫using u8

    var line3: []u8 = undefined;
    line3 = try allocator.alloc(u8, cat_widht + space_between + boxlength);
    std.mem.copy(u8, line3, cat[3]);
    std.mem.copy(u8, line3[cat_widht..line3.len], &spaces);
    line3[cat_widht + space_between] = '|';

    for (cat_widht + space_between + 1..line2.len - 1) |i| {
        line3[i] = ' ';
    }

    line3[line2.len - 1] = '|';

    buffer[3] = line3;

    // TODO: This is very ugly redo
    // Maybe let it render into a given buffer or something
    const box = try create_box(allocator, hostname, '|', '=', ' ');

    const name_length = if (box_width > hostname.len) box_width else hostname.len;
    const line_lenght = 1 + name_length + 2;

    var line4: []u8 = undefined;
    line4 = try allocator.alloc(u8, cat_widht + space_between + boxlength);

    std.mem.copy(u8, line4, box[0..line_lenght]);
    std.mem.copy(u8, line4[cat_widht..line4.len], &spaces);
    line4[cat_widht + space_between] = '|';
    for (cat_widht + space_between + 1..line4.len) |i| {
        line4[i] = '=';
    }

    line4[line4.len - 1] = '|';

    buffer[4] = line4;

    var line5: []u8 = undefined;
    line5 = try allocator.alloc(u8, line_lenght);

    std.mem.copy(u8, line5, box[line_lenght .. line_lenght * 2]);

    buffer[5] = line5;

    var line6: []u8 = undefined;
    line6 = try allocator.alloc(u8, line_lenght);

    std.mem.copy(u8, line6, box[line_lenght * 2 .. line_lenght * 3]);
    buffer[6] = line6;
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

    // Allocate the cat buffer
    var content: [cat_height + box_height + expand_height][]u8 = undefined;

    // Get the host name(wtf)
    var hostname: [std.os.HOST_NAME_MAX]u8 = undefined;
    const hostname_slice = try std.os.gethostname(&hostname);

    const user = std.os.getenv("LOGNAME") orelse "";

    //Render the cat to the buffer
    try renderCat(box_alloc, &content, hostname_slice, user);

    // Output the cat
    const stdout_file = std.io.getStdOut();

    try output(&content, stdout_file);
}
