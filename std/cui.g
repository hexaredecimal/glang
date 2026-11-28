// CUI bindings for Glang.
//
// CUI is an immediate-mode UI library for C by yappatronics:
// https://github.com/yappologistic/CUI
//
// The layout types below mirror CUI's public C structs. CUI's named-argument
// macros are C designated initializers, so Glang calls the *_ex functions with
// these structs explicitly. A zero-initialized options struct is the CUI
// default; set only the fields you need.

// ---------------------------------------------------------------------------
// Handles and basic value types
// ---------------------------------------------------------------------------

// Namespace for the Glang helpers at the bottom of this module.
struct std::cui {}

type CuiApp = void*;
type CuiCtx = void*;
type CuiId = uint;
type CuiTexture = size_t;

struct CuiVec2 {
  float x;
  float y;
}

struct CuiRect {
  float x;
  float y;
  float w;
  float h;
}

struct CuiCorners {
  float tl;
  float tr;
  float br;
  float bl;
}

type CuiPaintFn = void (*f)(CuiCtx, CuiRect, void*);

struct CuiCanvasResult {
  CuiRect rect;
  bool hovered;
  bool pressed;
  bool clicked;
  CuiVec2 mouse;
}

struct CuiColor {
  uchar r;
  uchar g;
  uchar b;
  uchar a;
}

enum CuiSizeKind {
  Fit,
  Grow,
  Fixed,
  Percent
}

// CUI's font handles are role indices into the active theme.
enum CuiFont {
  FontBody,
  FontMedium,
  FontDisplay,
  FontMono,
  FontIcons
}

struct CuiTextMetrics {
  float width;
  float height;
  float ascent;
  float descent;
  float line_height;
}

struct CuiSize {
  CuiSizeKind kind;
  float value;
}

enum CuiThemeMode {
  Light,
  Dark
}

enum CuiAccent {
  Neutral,
  Violet,
  Blue,
  Green,
  Amber,
  Orange,
  Coral,
  Rose
}

enum CuiRenderer {
  Auto,
  OpenGL,
  Software
}

enum CuiWindowState {
  Normal,
  Maximized,
  Minimized
}

enum CuiMouseButton {
  MouseLeft,
  MouseRight,
  MouseMiddle
}

enum CuiKey {
  KeyNone,
  KeyTab,
  KeyEnter,
  KeyEscape,
  KeyBackspace,
  KeyDelete,
  KeySpace,
  KeyLeft,
  KeyRight,
  KeyUp,
  KeyDown,
  KeyHome,
  KeyEnd,
  KeyPageUp,
  KeyPageDown,
  KeyA,
  KeyB,
  KeyC,
  KeyD,
  KeyE,
  KeyF,
  KeyG,
  KeyH,
  KeyI,
  KeyJ,
  KeyK,
  KeyL,
  KeyM,
  KeyN,
  KeyO,
  KeyP,
  KeyQ,
  KeyR,
  KeyS,
  KeyT,
  KeyU,
  KeyV,
  KeyW,
  KeyX,
  KeyY,
  KeyZ,
  Key0,
  Key1,
  Key2,
  Key3,
  Key4,
  Key5,
  Key6,
  Key7,
  Key8,
  Key9,
  KeyMinus,
  KeyEqual,
  KeyComma,
  KeyPeriod,
  KeySlash,
  KeyF1,
  KeyF2,
  KeyF3,
  KeyF4,
  KeyF5,
  KeyF6,
  KeyF7,
  KeyF8,
  KeyF9,
  KeyF10,
  KeyF11,
  KeyF12
}

enum CuiDir {
  Column,
  Row,
  Stack,
  Grid
}

enum CuiAlign {
  Default,
  Start,
  Center,
  End,
  Stretch
}

enum CuiJustify {
  JustifyStart,
  JustifyCenter,
  JustifyEnd,
  JustifyBetween,
  JustifyAround
}

enum CuiElevation {
  ElevationNone,
  Resting,
  Raised,
  Floating
}

enum CuiTextAlign {
  TextStart,
  TextCenter,
  TextRight,
  TextLeft,
  TextEnd
}

enum CuiButtonVariant {
  ButtonDefault,
  ButtonSecondary,
  ButtonPrimary,
  ButtonOutline,
  ButtonGhost,
  ButtonDanger,
  ButtonLink
}

enum CuiControlSize {
  SizeMedium,
  SizeSmall,
  SizeLarge
}

enum CuiDirection {
  DirectionInherit,
  DirectionLtr,
  DirectionRtl,
  DirectionAuto
}

enum CuiTone {
  ToneNeutral,
  ToneInfo,
  ToneSuccess,
  ToneWarning,
  ToneDanger,
  ToneViolet,
  ToneTeal,
  ToneRose,
  ToneAccent
}

enum CuiTabsVariant {
  TabsUnderline,
  TabsPill
}

enum CuiPlacement {
  PlaceBottomStart,
  PlaceBottom,
  PlaceBottomEnd,
  PlaceTopStart,
  PlaceTop,
  PlaceTopEnd,
  PlaceRightStart,
  PlaceLeftStart,
  PlaceRight,
  PlaceLeft
}

enum CuiToolbarStyle {
  ToolbarPlain,
  ToolbarGrouped,
  ToolbarFloating
}

// ---------------------------------------------------------------------------
// App layer (cui_app.h)
// ---------------------------------------------------------------------------

struct CuiWindowPlacement {
  int x;
  int y;
  int width;
  int height;
  CuiWindowState state;
  bool has_position;
}

struct CuiAppDesc {
  const char* title;
  int width;
  int height;
  int min_width;
  int min_height;
  bool fixed_size;
  bool continuous;
  bool no_vsync;
  bool hidden;
  CuiRenderer renderer;
  CuiThemeMode theme;
  CuiAccent accent;
  bool follow_system_theme;
  const char* app_id;
  CuiWindowPlacement* placement;
}

[[extern, c_abi]]
CuiApp cui_app_create(CuiAppDesc* desc);

[[extern, c_abi]]
void cui_app_destroy(CuiApp app);

[[extern, c_abi]]
bool cui_app_frame(CuiApp app);

[[extern, c_abi]]
CuiCtx cui_app_ui(CuiApp app);

[[extern, c_abi]]
void cui_app_quit(CuiApp app);

[[extern, c_abi]]
void cui_app_set_title(CuiApp app, const char* title);

[[extern, c_abi]]
void cui_app_set_size(CuiApp app, int width, int height);

[[extern, c_abi]]
CuiVec2 cui_app_size(CuiApp app);

[[extern, c_abi]]
void cui_app_maximize(CuiApp app);

[[extern, c_abi]]
void cui_app_minimize(CuiApp app);

[[extern, c_abi]]
void cui_app_restore(CuiApp app);

[[extern, c_abi]]
CuiWindowState cui_app_window_state(CuiApp app);

[[extern, c_abi]]
void cui_app_set_position(CuiApp app, int x, int y);

[[extern, c_abi]]
bool cui_app_placement(CuiApp app, CuiWindowPlacement* out);

[[extern, c_abi]]
bool cui_app_is_software(CuiApp app);

[[extern, c_abi]]
void* cui_app_native_window(CuiApp app);

[[extern, c_abi]]
const char* cui_app_backend(CuiApp app);

[[extern, c_abi]]
bool cui_app_screenshot(CuiApp app, void* rgba, int width, int height);

// ---------------------------------------------------------------------------
// Context, frames, and theme
// ---------------------------------------------------------------------------

[[extern, c_abi]]
void cui_set_theme(CuiCtx ui, CuiThemeMode mode);

[[extern, c_abi]]
CuiThemeMode cui_get_theme_mode(CuiCtx ui);

[[extern, c_abi]]
void cui_set_accent(CuiCtx ui, CuiAccent accent);

[[extern, c_abi]]
CuiAccent cui_get_accent(CuiCtx ui);

[[extern, c_abi]]
void cui_set_viewport(CuiCtx ui, float width, float height, float scale);

[[extern, c_abi]]
CuiVec2 cui_viewport_size(CuiCtx ui);

[[extern, c_abi]]
float cui_dpi_scale(CuiCtx ui);

// Absolute drawing, for canvas overlays and other custom chrome. These sit
// outside the layout pass and take screen-space rectangles.
[[extern, c_abi]]
void cui_draw_rect(CuiCtx ui, CuiRect rect, CuiCorners radius, CuiColor fill);

[[extern, c_abi]]
void cui_draw_rect_border(CuiCtx ui, CuiRect rect, CuiCorners radius, CuiColor fill, CuiColor border, float border_width);

[[extern, c_abi]]
void cui_draw_line(CuiCtx ui, CuiVec2 a, CuiVec2 b, float thickness, CuiColor color);

[[extern, c_abi]]
void cui_draw_polyline(CuiCtx ui, CuiVec2* points, int count, float thickness, CuiColor color, bool closed);

[[extern, c_abi]]
void cui_draw_arc(CuiCtx ui, CuiVec2 center, float radius, float a0, float a1, float thickness, CuiColor color);

[[extern, c_abi]]
void cui_draw_text(CuiCtx ui, CuiFont font, float size, CuiVec2 pos, CuiColor color, const char* text, int len);

[[extern, c_abi]]
void cui_draw_icon(CuiCtx ui, const char* icon, CuiRect rect, float size, CuiColor color);

[[extern, c_abi]]
CuiTextMetrics cui_measure_text(CuiCtx ui, CuiFont font, float size, const char* text, int len);

[[extern, c_abi]]
void cui_push_clip(CuiCtx ui, CuiRect rect);

[[extern, c_abi]]
void cui_pop_clip(CuiCtx ui);

// A canvas is a box painted by a callback after layout. Use it for overlays
// and custom surfaces; the callback runs in paint order and is clipped to the
// box. `user` is copied into frame storage when `user_size` is nonzero.
[[extern, c_abi]]
CuiCanvasResult cui_canvas(CuiCtx ui, const char* id, CuiSize width, CuiSize height, CuiPaintFn paint, const void* user, size_t user_size);

// Raw input and layout queries. These drive app-level canvas interactions:
// the last-rect/rect helpers report the geometry from the latest layout.
[[extern, c_abi]]
CuiVec2 cui_mouse_pos(CuiCtx ui);

[[extern, c_abi]]
bool cui_mouse_down(CuiCtx ui, CuiMouseButton button);

[[extern, c_abi]]
bool cui_mouse_clicked(CuiCtx ui, CuiMouseButton button);

[[extern, c_abi]]
bool cui_key_pressed(CuiCtx ui, CuiKey key);

// True while a text field owns the keyboard, so app shortcuts should stand down.
[[extern, c_abi]]
bool cui_wants_keyboard(CuiCtx ui);

[[extern, c_abi]]
bool cui_key_down(CuiCtx ui, CuiKey key);

[[extern, c_abi]]
CuiRect cui_last_rect(CuiCtx ui);

[[extern, c_abi]]
bool cui_last_hovered(CuiCtx ui);

[[extern, c_abi]]
CuiRect cui_get_rect(CuiCtx ui, CuiId id);

[[extern, c_abi]]
CuiId cui_make_id(CuiCtx ui, const char* str);

[[extern, c_abi]]
CuiId cui_last_id(CuiCtx ui);

[[extern, c_abi]]
float cui_delta_time(CuiCtx ui);

[[extern, c_abi]]
bool cui_needs_redraw(CuiCtx ui);

[[extern, c_abi]]
void cui_request_redraw(CuiCtx ui);

[[extern, c_abi]]
CuiColor cui_color_of(CuiCtx ui, CuiColor color);

// ---------------------------------------------------------------------------
// Layout
// ---------------------------------------------------------------------------

struct CuiBox {
  int _;
  const char* id;
  CuiDir dir;
  CuiSize width;
  CuiSize height;
  float min_width;
  float max_width;
  float min_height;
  float max_height;
  float pad;
  float pad_x;
  float pad_y;
  float pad_top;
  float pad_right;
  float pad_bottom;
  float pad_left;
  float gap;
  int columns;
  float min_column_width;
  bool wrap;
  CuiAlign align;
  CuiJustify justify;
  CuiColor bg;
  CuiColor border_color;
  float border;
  float radius;
  float radius_tl;
  float radius_tr;
  float radius_br;
  float radius_bl;
  CuiElevation elevation;
  bool scroll_x;
  bool scroll_y;
  bool clip;
  float opacity;
  CuiDirection direction;
}

struct CuiCardOpts {
  int _;
  const char* id;
  CuiSize width;
  CuiSize height;
  float min_width;
  float max_width;
  float pad;
  float pad_x;
  float pad_y;
  float gap;
  CuiDir dir;
  CuiAlign align;
  bool wrap;
  bool hoverable;
  bool muted;
  bool selected;
}

[[extern, c_abi]]
CuiId cui_box_begin(CuiCtx ui, CuiBox* opts);

[[extern, c_abi]]
void cui_box_end(CuiCtx ui);

[[extern, c_abi]]
CuiId cui_row_begin(CuiCtx ui, CuiBox* opts);

[[extern, c_abi]]
CuiId cui_column_begin(CuiCtx ui, CuiBox* opts);

[[extern, c_abi]]
bool cui_card_begin(CuiCtx ui, CuiCardOpts* opts);

[[extern, c_abi]]
void cui_card_end(CuiCtx ui);

[[extern, c_abi]]
void cui_spacer(CuiCtx ui);

[[extern, c_abi]]
void cui_gap(CuiCtx ui, float size);

[[extern, c_abi]]
void cui_separator(CuiCtx ui);

[[extern, c_abi]]
void cui_push_id(CuiCtx ui, const char* id);

[[extern, c_abi]]
void cui_push_id_int(CuiCtx ui, int value);

[[extern, c_abi]]
void cui_pop_id(CuiCtx ui);

[[extern, c_abi]]
void cui_push_disabled(CuiCtx ui, bool disabled);

[[extern, c_abi]]
void cui_pop_disabled(CuiCtx ui);

// ---------------------------------------------------------------------------
// Scrolling and split panes
// ---------------------------------------------------------------------------

struct CuiScrollOpts {
  int _;
  const char* id;
  CuiSize width;
  CuiSize height;
  bool horizontal;
  float pad;
  float gap;
  bool fade_edges;
  CuiColor fade_color;
}

[[extern, c_abi]]
void cui_scroll_begin(CuiCtx ui, CuiScrollOpts* opts);

[[extern, c_abi]]
void cui_scroll_end(CuiCtx ui);

[[extern, c_abi]]
void cui_scroll_to(CuiCtx ui, const char* scroll_id, float y);

struct CuiSplitOpts {
  int _;
  bool vertical;
  float min_first;
  float min_second;
  CuiSize width;
  CuiSize height;
}

[[extern, c_abi]]
void cui_split_begin(CuiCtx ui, const char* id, float* ratio, CuiSplitOpts* opts);

[[extern, c_abi]]
void cui_split_next(CuiCtx ui);

[[extern, c_abi]]
void cui_split_end(CuiCtx ui);

// ---------------------------------------------------------------------------
// Text
// ---------------------------------------------------------------------------

struct CuiTextOpts {
  int _;
  int font;
  float size;
  CuiColor color;
  CuiTextAlign align;
  bool nowrap;
  bool tabular;
  bool selectable;
  CuiSize width;
  float line_height;
  CuiDirection direction;
}

[[extern, c_abi]]
void cui_text_ex(CuiCtx ui, const char* text, CuiTextOpts* opts);

[[extern, c_abi]]
void cui_textf(CuiCtx ui, const char* fmt, void*...args);

[[extern, c_abi]]
void cui_heading(CuiCtx ui, const char* text, int level);

[[extern, c_abi]]
void cui_label(CuiCtx ui, const char* text);

[[extern, c_abi]]
void cui_secondary(CuiCtx ui, const char* text);

[[extern, c_abi]]
void cui_muted(CuiCtx ui, const char* text);

[[extern, c_abi]]
void cui_code(CuiCtx ui, const char* text);

[[extern, c_abi]]
void cui_kbd(CuiCtx ui, const char* keys);

[[extern, c_abi]]
bool cui_link(CuiCtx ui, const char* text);

[[extern, c_abi]]
void cui_icon(CuiCtx ui, const char* icon, float size, CuiColor color);

// ---------------------------------------------------------------------------
// Buttons and selection controls
// ---------------------------------------------------------------------------

struct CuiButtonOpts {
  int _;
  CuiButtonVariant variant;
  CuiControlSize size;
  const char* icon;
  const char* icon_right;
  bool disabled;
  bool loading;
  bool full_width;
  bool selected;
  const char* tooltip;
  const char* shortcut;
  CuiSize width;
  CuiColor color;
}

struct CuiCheckOpts {
  int _;
  const char* description;
  bool disabled;
  bool indeterminate;
}

struct CuiSliderOpts {
  int _;
  float step;
  bool show_value;
  const char* format;
  bool disabled;
  CuiSize width;
}

[[extern, c_abi]]
bool cui_button_ex(CuiCtx ui, const char* label, CuiButtonOpts* opts);

[[extern, c_abi]]
bool cui_icon_button_ex(CuiCtx ui, const char* icon, CuiButtonOpts* opts);

[[extern, c_abi]]
bool cui_checkbox_ex(CuiCtx ui, const char* label, bool* value, CuiCheckOpts* opts);

[[extern, c_abi]]
bool cui_switch_ex(CuiCtx ui, const char* label, bool* value, CuiCheckOpts* opts);

[[extern, c_abi]]
bool cui_radio_ex(CuiCtx ui, const char* label, int* value, int option, CuiCheckOpts* opts);

[[extern, c_abi]]
bool cui_slider_ex(CuiCtx ui, const char* label, float* value, float min, float max, CuiSliderOpts* opts);

// A Figma-style scrubbable number field: drag horizontally, or click to type.
struct CuiScrubOpts {
  int _;
  float step;
  const char* format;
  const char* suffix;
  const char* icon;
  CuiSize width;
}

[[extern, c_abi]]
bool cui_scrub_ex(CuiCtx ui, const char* label, float* value, float min, float max, CuiScrubOpts* opts);

[[extern, c_abi]]
bool cui_rating(CuiCtx ui, const char* id, int* value, int max);

struct CuiChipOpts {
  int _;
  const char* icon;
  bool disabled;
}

[[extern, c_abi]]
bool cui_chip_ex(CuiCtx ui, const char* label, bool* selected, CuiChipOpts* opts);

// ---------------------------------------------------------------------------
// Text input and select
// ---------------------------------------------------------------------------

struct CuiInputOpts {
  int _;
  const char* label;
  const char* placeholder;
  const char* icon;
  const char* hint;
  const char* error;
  bool password;
  bool disabled;
  bool clearable;
  bool autofocus;
  bool read_only;
  CuiControlSize size;
  CuiSize width;
  float height;
  const char* prefix;
  const char* suffix;
}

[[extern, c_abi]]
int cui_input_ex(CuiCtx ui, const char* id, char* buf, size_t cap, CuiInputOpts* opts);

[[extern, c_abi]]
int cui_textarea_ex(CuiCtx ui, const char* id, char* buf, size_t cap, CuiInputOpts* opts);

[[extern, c_abi]]
int cui_search_ex(CuiCtx ui, const char* id, char* buf, size_t cap, CuiInputOpts* opts);

struct CuiSelectOpts {
  int _;
  const char* label;
  const char* placeholder;
  char** icons;
  bool searchable;
  bool disabled;
  CuiSize width;
}

[[extern, c_abi]]
bool cui_select_ex(CuiCtx ui, const char* id, char** items, int count, int* index, CuiSelectOpts* opts);

// ---------------------------------------------------------------------------
// Feedback and display
// ---------------------------------------------------------------------------

struct CuiBadgeOpts {
  int _;
  CuiTone tone;
  bool dot;
  bool solid;
  const char* icon;
  CuiControlSize size;
}

struct CuiProgressOpts {
  int _;
  bool indeterminate;
  CuiTone tone;
  float height;
  const char* label;
  bool show_value;
  CuiSize width;
  bool dither;
}

// Charts. `values` is `float*` rather than CUI's `const float*` so Glang
// arrays can be passed directly; the layout is identical.
struct CuiSeries {
  const char* name;
  float* values;
  int count;
  CuiColor color;
}

struct CuiChartOpts {
  int _;
  CuiSize width;
  float height;
  char** labels;
  int label_count;
  bool area;
  bool no_grid;
  bool no_legend;
  bool stacked;
  bool smooth;
  const char* format;
  float min;
  float max;
  void* annotations;
  int annotation_count;
  bool dither;
}

struct CuiToastOpts {
  int _;
  const char* description;
  CuiTone tone;
  float duration;
  const char* action;
  bool show_timer;
}

struct CuiTabsOpts {
  int _;
  CuiTabsVariant variant;
  const char** icons;
  bool full_width;
}

struct CuiAlertOpts {
  int _;
  const char* description;
  CuiTone tone;
  const char* icon;
  bool dismissible;
}

[[extern, c_abi]]
void cui_badge_ex(CuiCtx ui, const char* text, CuiBadgeOpts* opts);

[[extern, c_abi]]
void cui_progress_ex(CuiCtx ui, float value, CuiProgressOpts* opts);

[[extern, c_abi]]
void cui_sparkline(CuiCtx ui, float* values, int count, CuiSize width, float height, CuiColor color);

[[extern, c_abi]]
void cui_line_chart_ex(CuiCtx ui, const char* id, CuiSeries* series, int count, CuiChartOpts* opts);

[[extern, c_abi]]
void cui_bar_chart_ex(CuiCtx ui, const char* id, CuiSeries* series, int count, CuiChartOpts* opts);

[[extern, c_abi]]
void cui_donut_chart_ex(CuiCtx ui, const char* id, float* values, char** labels, int count, CuiChartOpts* opts);

[[extern, c_abi]]
int cui_toast_ex(CuiCtx ui, const char* title, CuiToastOpts* opts);

[[extern, c_abi]]
bool cui_toast_action_clicked(CuiCtx ui, int handle);

[[extern, c_abi]]
void cui_toast_dismiss(CuiCtx ui, int handle);

// Glang emits `const char*[N]` arrays as `char*[N]`, so the parameter is
// `char**` to let callers pass `&labels[0]` directly. The C ABI is unchanged.
[[extern, c_abi]]
bool cui_tabs_ex(CuiCtx ui, const char* id, char** items, int count, int* index, CuiTabsOpts* opts);

[[extern, c_abi]]
bool cui_alert_ex(CuiCtx ui, const char* title, CuiAlertOpts* opts);

// ---------------------------------------------------------------------------
// App chrome: menu bar, toolbar, status bar, document tabs
// ---------------------------------------------------------------------------

struct CuiMenuBarOpts {
  int _;
  bool no_border;
}

struct CuiMenuBarMenuOpts {
  int _;
  char mnemonic;
  float width;
  bool disabled;
}

struct CuiMenuItemOpts {
  int _;
  const char* icon;
  const char* shortcut;
  bool danger;
  bool disabled;
  bool checked;
  int font;
  float text_size;
}

struct CuiMenuOpts {
  int _;
  const char* icon;
  CuiButtonVariant variant;
  CuiPlacement placement;
  float width;
  bool icon_only;
}

[[extern, c_abi]]
void cui_menu_bar_begin(CuiCtx ui, const char* id, CuiMenuBarOpts* opts);

[[extern, c_abi]]
void cui_menu_bar_end(CuiCtx ui);

[[extern, c_abi]]
bool cui_menu_bar_menu_begin(CuiCtx ui, const char* label, CuiMenuBarMenuOpts* opts);

[[extern, c_abi]]
void cui_menu_bar_menu_end(CuiCtx ui);

[[extern, c_abi]]
bool cui_menu_begin(CuiCtx ui, const char* label, CuiMenuOpts* opts);

[[extern, c_abi]]
void cui_menu_end(CuiCtx ui);

[[extern, c_abi]]
bool cui_menu_item_ex(CuiCtx ui, const char* label, CuiMenuItemOpts* opts);

[[extern, c_abi]]
void cui_menu_separator(CuiCtx ui);

[[extern, c_abi]]
void cui_menu_label(CuiCtx ui, const char* text);

[[extern, c_abi]]
void cui_tooltip(CuiCtx ui, const char* text);

struct CuiToolbarOpts {
  int _;
  bool no_border;
  CuiToolbarStyle style;
}

struct CuiToolOpts {
  int _;
  const char* label;
  const char* tooltip;
  const char* shortcut;
  bool* toggle;
  bool disabled;
  CuiTone tone;
  bool flyout;
}

struct CuiToolbarRadioOpts {
  int _;
  const char** labels;
}

[[extern, c_abi]]
void cui_toolbar_begin(CuiCtx ui, const char* id, CuiToolbarOpts* opts);

[[extern, c_abi]]
void cui_toolbar_end(CuiCtx ui);

[[extern, c_abi]]
bool cui_toolbar_button_ex(CuiCtx ui, const char* icon, CuiToolOpts* opts);

[[extern, c_abi]]
void cui_toolbar_separator(CuiCtx ui);

[[extern, c_abi]]
void cui_toolbar_spacer(CuiCtx ui);

[[extern, c_abi]]
void cui_toolbar_group_begin(CuiCtx ui);

[[extern, c_abi]]
void cui_toolbar_group_end(CuiCtx ui);

[[extern, c_abi]]
bool cui_toolbar_radio_ex(CuiCtx ui, const char* id, const char** icons, int count, int* index, CuiToolbarRadioOpts* opts);

[[extern, c_abi]]
bool cui_toolbar_primary_ex(CuiCtx ui, const char* icon, CuiToolOpts* opts);

[[extern, c_abi]]
bool cui_toolbar_cycle_ex(CuiCtx ui, const char* id, const char** items, int count, int* index, CuiToolOpts* opts);

[[extern, c_abi]]
void cui_flyout_mark(CuiCtx ui);

struct CuiStatusBarOpts {
  int _;
  bool no_border;
}

struct CuiStatusItemOpts {
  int _;
  const char* icon;
  CuiTone tone;
  const char* tooltip;
  bool disabled;
}

struct CuiStatusProgressOpts {
  int _;
  const char* label;
  bool indeterminate;
  float width;
}

[[extern, c_abi]]
void cui_status_bar_begin(CuiCtx ui, const char* id, CuiStatusBarOpts* opts);

[[extern, c_abi]]
void cui_status_bar_end(CuiCtx ui);

[[extern, c_abi]]
void cui_status_bar_spacer(CuiCtx ui);

[[extern, c_abi]]
void cui_status_bar_text_ex(CuiCtx ui, const char* text, CuiStatusItemOpts* opts);

[[extern, c_abi]]
bool cui_status_bar_item_ex(CuiCtx ui, const char* label, CuiStatusItemOpts* opts);

[[extern, c_abi]]
void cui_status_bar_progress_ex(CuiCtx ui, float value, CuiStatusProgressOpts* opts);

struct CuiDocTab {
  const char* title;
  const char* icon;
  const char* tooltip;
  bool dirty;
}

struct CuiDocTabsOpts {
  int _;
  bool shortcuts;
  bool no_close;
  bool no_reorder;
}

struct CuiDocTabsResult {
  bool changed;
  int close;
  int move_from;
  int move_to;
}

[[extern, c_abi]]
CuiDocTabsResult cui_doc_tabs_ex(CuiCtx ui, const char* id, CuiDocTab* tabs, int count, int* selected, CuiDocTabsOpts* opts);

// ---------------------------------------------------------------------------
// Navigation, trees, lists, and tab bars
// ---------------------------------------------------------------------------

struct CuiNavOpts {
  int _;
  const char* icon;
  const char* badge;
  bool selected;
  const char* group;
}

[[extern, c_abi]]
bool cui_nav_item_ex(CuiCtx ui, const char* label, CuiNavOpts* opts);

[[extern, c_abi]]
void cui_nav_section(CuiCtx ui, const char* title);

[[extern, c_abi]]
int cui_breadcrumb(CuiCtx ui, const char** items, int count);

struct CuiTreeOpts {
  int _;
  const char* icon;
  bool leaf;
  bool selected;
}

[[extern, c_abi]]
bool cui_tree_begin(CuiCtx ui, const char* label, bool* open, CuiTreeOpts* opts);

[[extern, c_abi]]
void cui_tree_end(CuiCtx ui);

[[extern, c_abi]]
bool cui_tree_clicked(CuiCtx ui);

struct CuiListItemOpts {
  int _;
  const char* icon;
  const char* subtitle;
  const char* trailing;
  bool selected;
  const char* avatar;
}

[[extern, c_abi]]
bool cui_list_item_ex(CuiCtx ui, const char* title, CuiListItemOpts* opts);

struct CuiTabBarItem {
  const char* icon;
  const char* label;
  int badge;
}

struct CuiTabBarOpts {
  int _;
  CuiSize width;
  bool labels_on_selected_only;
}

[[extern, c_abi]]
bool cui_tab_bar_ex(CuiCtx ui, const char* id, CuiTabBarItem* items, int count, int* selected, CuiTabBarOpts* opts);

// ---------------------------------------------------------------------------
// Popovers, avatars, empty states, command palette
// ---------------------------------------------------------------------------

struct CuiPopoverOpts {
  int _;
  CuiPlacement placement;
  float width;
  float pad;
  float gap;
}

[[extern, c_abi]]
bool cui_popover_begin(CuiCtx ui, const char* id, CuiPopoverOpts* opts);

[[extern, c_abi]]
void cui_popover_end(CuiCtx ui);

[[extern, c_abi]]
void cui_popover_open(CuiCtx ui, const char* id);

[[extern, c_abi]]
void cui_popover_close(CuiCtx ui, const char* id);

[[extern, c_abi]]
void cui_popover_toggle(CuiCtx ui, const char* id);

[[extern, c_abi]]
bool cui_popover_is_open(CuiCtx ui, const char* id);

struct CuiAvatarOpts {
  int _;
  float size;
  size_t image;
  const char* status;
  bool square;
}

[[extern, c_abi]]
void cui_avatar_ex(CuiCtx ui, const char* name, CuiAvatarOpts* opts);

[[extern, c_abi]]
void cui_avatar_group(CuiCtx ui, const char** names, int count, int max_visible, float size);

struct CuiEmptyOpts {
  int _;
  const char* icon;
  const char* description;
  const char* action;
}

[[extern, c_abi]]
bool cui_empty_state_ex(CuiCtx ui, const char* title, CuiEmptyOpts* opts);

struct CuiCommand {
  const char* title;
  const char* icon;
  const char* group;
  const char* shortcut;
}

[[extern, c_abi]]
int cui_command_palette(CuiCtx ui, bool* open, CuiCommand* commands, int count);

// ---------------------------------------------------------------------------
// Code editor
// ---------------------------------------------------------------------------

struct CuiTextMark {
  int start;
  int end;
  int color;
}

struct CuiCodeEditorOpts {
  int _;
  const char* lang;
  CuiSize width;
  float height;
  float size;
  int tab_size;
  bool use_tabs;
  bool read_only;
  bool no_line_numbers;
  bool autofocus;
  const char* placeholder;
  CuiTextMark* marks;
  int mark_count;
}

struct CuiCodeEditorResult {
  bool changed;
  bool refused;
  bool focused;
  int cursor;
  int anchor;
  int line;
  int column;
  int line_count;
  int length;
  int bracket;
  int bracket_match;
  int find_matches;
  int find_index;
}

[[extern, c_abi]]
CuiCodeEditorResult cui_code_editor_ex(CuiCtx ui, const char* id, char* buf, size_t cap, CuiCodeEditorOpts* opts);

[[extern, c_abi]]
void cui_code_editor_goto(CuiCtx ui, const char* id, int line, int column);

// ---------------------------------------------------------------------------
// Glang helpers
// ---------------------------------------------------------------------------

CuiSize std::cui::fit() => CuiSize{kind: CuiSizeKind::Fit, value: 0.0};

CuiSize std::cui::grow(float weight) => CuiSize{kind: CuiSizeKind::Grow, value: weight};

CuiSize std::cui::fill() => CuiSize{kind: CuiSizeKind::Grow, value: 1.0};

CuiSize std::cui::px(float value) => CuiSize{kind: CuiSizeKind::Fixed, value: value};

CuiSize std::cui::pct(float value) => CuiSize{kind: CuiSizeKind::Percent, value: value};

CuiColor std::cui::rgb(int r, int g, int b) =>
  CuiColor{r: r as uchar, g: g as uchar, b: b as uchar, a: 255};

CuiColor std::cui::rgba(int r, int g, int b, int a) =>
  CuiColor{r: r as uchar, g: g as uchar, b: b as uchar, a: a as uchar};

CuiColor std::cui::tokenColor(CuiCtx ui, int token) {
  return cui_color_of(ui, CuiColor{r: token as uchar, g: 197, b: 29, a: 0});
}

CuiAppDesc std::cui::appDesc(const char* title, int width, int height) =>
  CuiAppDesc{title: title, width: width, height: height};

// ---------------------------------------------------------------------------
// Lucide icon helpers
// ---------------------------------------------------------------------------
//
// CUI's icon font is addressed by UTF-8 code points, normally through the
// CUI_ICON_* macros. Glang cannot include those macros, so the icons used by
// the bindings live here as small typed helpers.

struct std::cui::icons {}

const char* std::cui::icons::check() => "\xee\x81\xac";
const char* std::cui::icons::x() => "\xee\x86\xb2";
const char* std::cui::icons::plus() => "\xee\x84\xbd";
const char* std::cui::icons::minus() => "\xee\x84\x9c";
const char* std::cui::icons::chevronDown() => "\xee\x81\xad";
const char* std::cui::icons::chevronRight() => "\xee\x81\xaf";
const char* std::cui::icons::search() => "\xee\x85\x91";
const char* std::cui::icons::settings() => "\xee\x85\x94";
const char* std::cui::icons::user() => "\xee\x86\x9f";
const char* std::cui::icons::bell() => "\xee\x81\x99";
const char* std::cui::icons::trash() => "\xee\x86\x8e";
const char* std::cui::icons::pencil() => "\xee\x87\xb9";
const char* std::cui::icons::copy() => "\xee\x82\x9e";
const char* std::cui::icons::eye() => "\xee\x82\xba";
const char* std::cui::icons::info() => "\xee\x83\xb9";
const char* std::cui::icons::alert() => "\xee\x81\xb7";
const char* std::cui::icons::checkCircle() => "\xee\x88\xa6";
const char* std::cui::icons::more() => "\xee\x82\xb6";
const char* std::cui::icons::panelLeft() => "\xee\x84\xaa";
const char* std::cui::icons::file() => "\xee\x83\x80";
const char* std::cui::icons::folder() => "\xee\x83\x97";
const char* std::cui::icons::folderOpen() => "\xee\x89\x87";
const char* std::cui::icons::fileText() => "\xee\x83\x8c";
const char* std::cui::icons::package() => "\xee\x84\xa9";
const char* std::cui::icons::gitBranch() => "\xee\x83\xa2";
const char* std::cui::icons::play() => "\xee\x84\xbc";
const char* std::cui::icons::pause() => "\xee\x84\xae";
const char* std::cui::icons::stop() => "\xee\x85\xa7";
const char* std::cui::icons::bug() => "\xee\x88\x8c";
const char* std::cui::icons::circleCheck() => "\xee\x88\xa6";
const char* std::cui::icons::terminal() => "\xee\x86\x81";
const char* std::cui::icons::code() => "\xee\x82\x93";
const char* std::cui::icons::command() => "\xee\x82\x9a";
const char* std::cui::icons::save() => "\xee\x85\x8d";
const char* std::cui::icons::database() => "\xee\x82\xad";
const char* std::cui::icons::server() => "\xee\x85\x93";
const char* std::cui::icons::cpu() => "\xee\x82\xa9";
const char* std::cui::icons::globe() => "\xee\x83\xa8";
const char* std::cui::icons::sparkles() => "\xee\x90\x92";
const char* std::cui::icons::dashboard() => "\xee\x87\x81";
const char* std::cui::icons::activity() => "\xee\x80\xb8";
const char* std::cui::icons::layers() => "\xee\x94\xa9";
const char* std::cui::icons::refresh() => "\xee\x85\x85";
const char* std::cui::icons::undo() => "\xee\x8a\xa1";
const char* std::cui::icons::redo() => "\xee\x8a\xa0";
const char* std::cui::icons::arrowLeft() => "\xee\x81\x88";
const char* std::cui::icons::arrowRight() => "\xee\x81\x89";
const char* std::cui::icons::download() => "\xee\x82\xb2";
const char* std::cui::icons::upload() => "\xee\x86\x9e";
const char* std::cui::icons::list() => "\xee\x84\x86";
const char* std::cui::icons::grid() => "\xee\x83\xa9";
const char* std::cui::icons::maximize() => "\xee\x84\x93";
const char* std::cui::icons::minimize() => "\xee\x84\x9b";
const char* std::cui::icons::zoomIn() => "\xee\x86\xb6";
const char* std::cui::icons::zoomOut() => "\xee\x86\xb7";
const char* std::cui::icons::clock() => "\xee\x82\x87";
const char* std::cui::icons::bookmark() => "\xee\x81\xa0";
const char* std::cui::icons::chartBar() => "\xee\x8a\xa2";
const char* std::cui::icons::chartLine() => "\xee\x8a\xa5";
const char* std::cui::icons::inbox() => "\xee\x83\xb7";
const char* std::cui::icons::send() => "\xee\x85\x92";
const char* std::cui::icons::message() => "\xee\x84\x97";
const char* std::cui::icons::tag() => "\xee\x85\xbf";
const char* std::cui::icons::zap() => "\xee\x86\xb4";
const char* std::cui::icons::shield() => "\xee\x85\x98";
const char* std::cui::icons::rocket() => "\xee\x8a\x86";
const char* std::cui::icons::target() => "\xee\x86\x80";
const char* std::cui::icons::compass() => "\xee\x82\x9b";
const char* std::cui::icons::history() => "\xee\x87\xb5";
const char* std::cui::icons::archive() => "\xee\x81\x81";
const char* std::cui::icons::filter() => "\xee\x83\x9c";
const char* std::cui::icons::sliders() => "\xee\x8a\x9a";
const char* std::cui::icons::grip() => "\xee\x83\xab";
const char* std::cui::icons::home() => "\xee\x83\xb5";
const char* std::cui::icons::square() => "\xee\x85\xa7";
const char* std::cui::icons::box() => "\xee\x81\xa1";
const char* std::cui::icons::textTool() => "\xee\x86\x98";
const char* std::cui::icons::move() => "\xee\x84\xa1";
const char* std::cui::icons::star() => "\xee\x85\xb6";
const char* std::cui::icons::circle() => "\xee\x81\xb6";
const char* std::cui::icons::help() => "\xee\x82\x82";
const char* std::cui::icons::sun() => "\xee\x85\xb8";
const char* std::cui::icons::eyeOff() => "\xee\x82\xbb";
const char* std::cui::icons::link() => "\xee\x84\x82";
const char* std::cui::icons::rotateCcw() => "\xee\x85\x88";
const char* std::cui::icons::alignLeft() => "\xee\x86\x85";
const char* std::cui::icons::palette() => "\xee\x87\x9d";
