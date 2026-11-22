// A small Glang app built with CUI, the immediate-mode C UI library by
// yappatronics: https://github.com/yappologistic/CUI
//
// Build after transpiling with gcli; see examples/cui/README.md. Run it
// normally for an interactive window, or set CUI_SMOKE=1 to open a hidden
// window for three frames and exit (used by the build smoke check).

import std.cui;

[[extern, c_abi]]
char* getenv(const char* name);

int main() {
  bool smoke = getenv("CUI_SMOKE") != nullptr;

  CuiAppDesc desc = CuiAppDesc{
    title: "Glang + CUI",
    width: 560,
    height: 460,
    theme: CuiThemeMode::Light,
    accent: CuiAccent::Blue,
    hidden: smoke,
    continuous: smoke
  };

  CuiApp app = cui_app_create(&desc);
  if (app == nullptr) {
    return 1;
  }
  defer cui_app_destroy(app);

  bool notifications = true;
  bool compact = false;
  float volume = 0.5;
  int clicks = 0;
  int frames = 0;
  char[64] name;
  name[0] = '\0';

  while (cui_app_frame(app)) {
    CuiCtx ui = cui_app_ui(app);

    CuiBox page = CuiBox{pad: 28.0, gap: 14.0, width: std::cui::fill()};
    cui_column_begin(ui, &page);

    cui_heading(ui, "Hello from Glang", 2);
    cui_secondary(ui, "CUI is an immediate-mode C UI library. This window and every widget below is built by Glang.");

    CuiBadgeOpts badge = CuiBadgeOpts{tone: CuiTone::ToneInfo, dot: true};
    cui_badge_ex(ui, "immediate mode", &badge);
    cui_separator(ui);

    CuiCardOpts card = CuiCardOpts{pad: 18.0, gap: 10.0};
    cui_card_begin(ui, &card);
    cui_label(ui, "Controls");
    cui_muted(ui, "Each control reads and writes a Glang variable every frame.");

    CuiCheckOpts check = CuiCheckOpts{description: "Switches return true when their value changes."};
    if (cui_switch_ex(ui, "Notifications", &notifications, &check)) {
      const char* message = "Notifications disabled";
      if (notifications) {
        message = "Notifications enabled";
      }
      CuiToastOpts toast = CuiToastOpts{
        description: message,
        tone: CuiTone::ToneSuccess,
        duration: 2.0
      };
      cui_toast_ex(ui, "Settings changed", &toast);
    }

    CuiCheckOpts compactCheck = CuiCheckOpts{};
    cui_checkbox_ex(ui, "Compact layout", &compact, &compactCheck);

    CuiSliderOpts slider = CuiSliderOpts{show_value: true};
    cui_slider_ex(ui, "Volume", &volume, 0.0, 1.0, &slider);

    CuiInputOpts input = CuiInputOpts{label: "Your name", placeholder: "Type here"};
    cui_input_ex(ui, "name", &name[0], 64, &input);

    CuiBox row = CuiBox{gap: 8.0, align: CuiAlign::Center};
    cui_row_begin(ui, &row);

    CuiButtonOpts primary = CuiButtonOpts{variant: CuiButtonVariant::ButtonPrimary};
    if (cui_button_ex(ui, "Click me", &primary)) {
      clicks++;
    }

    CuiButtonOpts outline = CuiButtonOpts{variant: CuiButtonVariant::ButtonOutline};
    if (cui_button_ex(ui, "Reset", &outline)) {
      clicks = 0;
    }

    cui_box_end(ui);
    cui_card_end(ui);

    cui_textf(ui, "Clicked %d times", clicks);
    cui_textf(ui, "Name: %s", &name[0]);

    CuiProgressOpts progress = CuiProgressOpts{
      label: "Click progress",
      show_value: true,
      tone: CuiTone::ToneAccent
    };
    float percent = (clicks * 10) as float;
    if (percent > 100.0) {
      percent = 100.0;
    }
    cui_progress_ex(ui, percent, &progress);

    cui_spacer(ui);
    cui_muted(ui, "Close the window to exit. Set CUI_SMOKE=1 for a three-frame smoke run.");
    cui_box_end(ui);

    frames++;
    if (smoke && frames >= 3) {
      cui_app_quit(app);
    }
  }

  return 0;
}
