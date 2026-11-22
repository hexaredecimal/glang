// Minimal std.gui builder example.

import std.gui;
import std.pipe;

int main() {
  int clicks = 0;

  auto window = Window::new()
    |> set_size(520px, 340px)
    |> set_title("Hello, world");

  auto root = Column::new()
    |> set_size(fill(), fill())
    |> set_padding(28.0)
    |> set_gap(14.0)
    |> set_align(GuiAlign::GuiAlignStart)
    |> set_bg(gui::rgb(248, 249, 251));

  auto heading = Text::new()
    |> set_text("Hello, world")
    |> set_text_size(30.0)
    |> set_font(gui::display())
    |> set_text_color(gui::rgb(24, 28, 36));

  auto caption = Text::new()
    |> set_text("This window is built entirely with std.gui.")
    |> set_text_size(13.0)
    |> set_text_color(gui::rgb(105, 112, 124));

  auto button = Button::new()
    |> set_size(150px, 42px)
    |> set_text("Click Me")
    |> set_text_size(13.0)
    |> set_bg(gui::rgb(10, 207, 131))
    |> set_text_color(gui::rgb(15, 23, 38))
    |> set_radius(8.0)
    |> on_click() { -> clicks = clicks + 1; return; };

  auto count = Text::new()
    |> set_text("Clicked 0 times")
    |> set_text_size(12.0)
    |> set_text_color(gui::rgb(105, 112, 124));

  root.add(heading);
  root.add(caption);
  root.add(button);
  root.add(count);
  window.add(root);

  return gui::run(window);
}
