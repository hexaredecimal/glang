import std.raylib.raylib : Raylib;

void main() {
  Raylib::InitWindow(800, 450, "Glang + raylib");
  Raylib::SetTargetFPS(60);
  defer Raylib::CloseWindow();

  while (!Raylib::WindowShouldClose()) {
    Raylib::BeginDrawing();
    Raylib::ClearBackground(Raylib::RAYWHITE);
    Raylib::DrawText("Hello from Glang", 20, 20, 24, Raylib::DARKGRAY);
    if (Raylib::IsKeyDown(Raylib::KEY_SPACE)) {
      Raylib::DrawText("Space is down", 20, 55, 20, Raylib::BLUE);
    }
    Raylib::EndDrawing();
  }
}
