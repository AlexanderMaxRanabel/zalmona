const rl = @import("raylib");

const MAX_COLUMNS = 20;

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

    var heights: [MAX_COLUMNS]f32 = undefined;
    var positions: [MAX_COLUMNS]rl.Vector3 = undefined;
    var colors: [MAX_COLUMNS]rl.Color = undefined;

    for (0..heights.len) |i| { //generates random positions and colors
        heights[i] = @as(f32, @floatFromInt(rl.getRandomValue(1, 12)));
        positions[i] = rl.Vector3.init(
            @as(f32, @floatFromInt(rl.getRandomValue(-15, 15))),
            heights[i] / 2.0,
            @as(f32, @floatFromInt(rl.getRandomValue(-15, 15))),
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

    var ray: rl.Ray = undefined; // Picking line ray
    var collision: rl.RayCollision = undefined; // Ray collision hit info
    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
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

                // Check collision between ray and box
                collision = rl.getRayCollisionBox(ray, rl.BoundingBox{
                    .max = rl.Vector3.init(cubePosition.x - cubeSize.x / 2, cubePosition.y - cubeSize.y / 2, cubePosition.z - cubeSize.z / 2),
                    .min = rl.Vector3.init(cubePosition.x + cubeSize.x / 2, cubePosition.y + cubeSize.y / 2, cubePosition.z + cubeSize.z / 2),
                });
            } else collision.hit = false;
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.ray_white);

        {
            camera.begin();
            defer camera.end();

            // Draw ground
            rl.drawPlane(rl.Vector3.init(0, 0, 0), rl.Vector2.init(32, 32), rl.Color.light_gray);
            rl.drawCube(rl.Vector3.init(-16.0, 2.5, 0.0), 1.0, 5.0, 32.0, rl.Color.blue); // Draw a blue wall
            rl.drawCube(rl.Vector3.init(16.0, 2.5, 0.0), 1.0, 5.0, 32.0, rl.Color.lime); // Draw a green wall
            rl.drawCube(rl.Vector3.init(0.0, 2.5, 16.0), 32.0, 5.0, 1.0, rl.Color.gold); // Draw a yellow wall

            // Draw some cubes around
            for (heights, 0..) |height, i| {
                rl.drawCube(positions[i], 2.0, height, 2.0, colors[i]);
                rl.drawCubeWires(positions[i], 2.0, height, 2.0, rl.Color.maroon);
            }

            if (collision.hit) {
                rl.drawCube(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.Color.red);
                rl.drawCubeWires(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.Color.maroon);

                rl.drawCubeWires(cubePosition, cubeSize.x + 0.2, cubeSize.y + 0.2, cubeSize.z + 0.2, rl.Color.green);
            } else {
                rl.drawCube(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.Color.gray);
                rl.drawCubeWires(cubePosition, cubeSize.x, cubeSize.y, cubeSize.z, rl.Color.dark_gray);
                //rl.drawCube(collision);
            }

            rl.drawRay(ray, rl.Color.maroon);
            rl.drawGrid(10, 1);
        }

        rl.drawRectangle(10, 10, 220, 70, rl.Color.sky_blue.fade(0.5));
        rl.drawRectangleLines(10, 10, 220, 70, rl.Color.blue);

        rl.drawText("First person camera default controls:", 20, 20, 10, rl.Color.black);
        rl.drawText("- Move with keys: W, A, S, D", 40, 40, 10, rl.Color.dark_gray);
        rl.drawText("- Mouse move to look around", 40, 60, 10, rl.Color.dark_gray);
    }
}
