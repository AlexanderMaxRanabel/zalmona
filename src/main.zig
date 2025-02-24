const rl = @import("raylib");
const std = @import("std");

const MAX_COLUMNS = 30;

pub fn getdirection_vector(first_vector: rl.Vector3, second_vector: rl.Vector3) rl.Vector3 {
    const third_vector: rl.Vector3 = rl.Vector3.subtract(first_vector, second_vector);
    return third_vector;
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 1920;
    const screenHeight = 1080;

    rl.initWindow(screenWidth, screenHeight, "Zalmona");
    defer rl.closeWindow(); // Close window and OpenGL context

    var camera = rl.Camera3D{
        .position = rl.Vector3.init(4, 2, 4),
        .target = rl.Vector3.init(0, 1.8, 0),
        .up = rl.Vector3.init(0, 1, 0),
        .fovy = 60,
        .projection = .perspective,
    };

    const Enemy_Struct = struct { position: rl.Vector3, color: rl.Color, height: f32, distance: f32 };

    const enemy = Enemy_Struct{
        .position = rl.Vector3.init(4.0, 2.0, 5.0),
        .color = rl.Color.init(255, 255, 255, 255),
        .height = 4.0,
        .distance = 0.0,
    };

    var heights: [MAX_COLUMNS]f32 = undefined;
    var positions: [MAX_COLUMNS]rl.Vector3 = undefined;
    var colors: [MAX_COLUMNS]rl.Color = undefined;

    for (0..heights.len) |i| { //generates random positions and colors
        heights[i] = @as(f32, @floatFromInt(rl.getRandomValue(1, 24)));
        positions[i] = rl.Vector3.init(
            @as(f32, @floatFromInt(rl.getRandomValue(-30, 30))),
            //heights[i] / 2.0,
            @as(f32, @floatFromInt(rl.getRandomValue(0, 15))),
            @as(f32, @floatFromInt(rl.getRandomValue(-30, 30))),
        );
        colors[i] = rl.Color.init(
            @as(u8, @intCast(rl.getRandomValue(20, 255))),
            @as(u8, @intCast(rl.getRandomValue(10, 55))),
            30,
            255,
        );
    }

    const cubePosition = rl.Vector3.init(0, 1, 0);
    const cubeSize = rl.Vector3.init(3, 3, 3);
    //var p_height: f32 = 0.0;
    var ray: rl.Ray = undefined; // Picking line ray
    var collision: rl.RayCollision = undefined; // Ray collision hit info
    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    const speed: f32 = 5.0;
    var draw_call = false;
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        camera.update(.first_person);
        if (rl.isCursorHidden()) rl.updateCamera(&camera, .first_person);

        // Toggle camera controls
        if (rl.isMouseButtonPressed(.right)) {
            if (rl.isCursorHidden()) rl.enableCursor() else rl.disableCursor();
        }

        if (rl.isMouseButtonPressed(.left)) {
            if (!collision.hit) {
                ray = rl.getScreenToWorldRay(rl.getMousePosition(), camera);
                collision = rl.getRayCollisionBox(ray, rl.BoundingBox{
                    .max = rl.Vector3.init(cubePosition.x - cubeSize.x / 2, cubePosition.y - cubeSize.y / 2, cubePosition.z - cubeSize.z / 2),
                    .min = rl.Vector3.init(cubePosition.x + cubeSize.x / 2, cubePosition.y + cubeSize.y / 2, cubePosition.z + cubeSize.z / 2),
                });
            } else collision.hit = false;
        }

        if (rl.isKeyDown(.up)) {
            camera.fovy += 1;
        }

        if (rl.isKeyDown(.down)) {
            camera.fovy -= 1;
        }

        if (rl.isKeyPressed(.g)) {
            draw_call = true;
        }

        if (rl.isKeyDown(.space)) {
            camera.position.y += 0.1;
        }

        if (rl.isKeyDown(.left_shift)) {
            camera.position.y -= 0.1;
        }

        var enemy_direction = getdirection_vector(enemy.position, camera.position);
        enemy_direction.z += speed * rl.getFrameTime(); // Now it mutates, and the warning disappears

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);
        {
            camera.begin();
            defer camera.end();

            // Draw ground
            rl.drawPlane(rl.Vector3.init(0, 0, 0), rl.Vector2.init(64, 64), rl.Color.light_gray);
            rl.drawCube(rl.Vector3.init(-32.0, 2.5, 0.0), 1.0, 5.0, 32.0, rl.Color.blue); // Draw a blue wall
            rl.drawCube(rl.Vector3.init(32.0, 2.5, 0.0), 1.0, 5.0, 32.0, rl.Color.lime); // Draw a green wall
            rl.drawCube(rl.Vector3.init(0.0, 2.5, 32.0), 32.0, 5.0, 1.0, rl.Color.gold); // Draw a yellow wall
            rl.drawSphere(enemy_direction, 3.0, rl.Color.green);

            // Draw some cubes around
            for (heights, 0..) |height, i| {
                rl.drawCube(positions[i], 2.0, height, 2.0, colors[i]);
                rl.drawCubeWires(positions[i], 2.0, height, 2.0, rl.Color.maroon);
            }

            //const enemy_position: rl.Vector3.
            rl.drawCube(cubePosition, 2.0, 2.0, 2.0, rl.Color.blue);
            rl.drawCube(enemy_direction, 2.0, enemy.height, 2.0, enemy.color);
            if (collision.hit) {
                rl.drawCube(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.Color.red);
                rl.drawCubeWires(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.Color.maroon);
            }

            rl.drawRay(ray, rl.Color.maroon);
            rl.drawGrid(10, 1);
            if (draw_call == true) {
                rl.drawCube(rl.Vector3.init(0.0, 5.0, 0.5), 1.0, 5.0, 32.0, rl.Color.blue);
            }
        }

        rl.drawRectangle(10, 10, 220, 70, rl.Color.sky_blue.fade(0.5));
        rl.drawRectangleLines(10, 10, 220, 70, rl.Color.blue);

        rl.drawText("First person camera default controls:", 20, 20, 10, rl.Color.black);
        rl.drawText("- Move with keys: W, A, S, D", 40, 40, 10, rl.Color.dark_gray);
        rl.drawText("- Mouse move to look around", 40, 60, 10, rl.Color.dark_gray);
    }
}
