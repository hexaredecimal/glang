// A builder-pattern GUI library for Glang, rendered by CUI.
//
// Widgets are immutable-by-convention values connected with `|>`:
//
//   import std.gui;
//   import std.pipe;
//
//   auto window = Window::new()
//     |> set_size(960px, 640px)
//     |> set_title("Hello, world");
//
//   auto button = Button::new()
//     |> set_text("Click Me")
//     |> on_click() { -> ...; return; };
//
//   window.add(button);
//   gui::run(window);
//
// A window can also rebuild its tree every frame, which is the easiest way to
// write data-driven editors:
//
//   window.on_build() { -> buildUi(window); return; };
//
// Every widget is stored in a frame arena, so rebuilds stay allocation-free.

import std.cui;

[[extern, c_abi]]
char* getenv(const char* name);

// ---------------------------------------------------------------------------
// Public value types
// ---------------------------------------------------------------------------

struct Color {
  uchar r;
  uchar g;
  uchar b;
  uchar a;
}

struct Rect {
  float x;
  float y;
  float w;
  float h;
}

enum LengthKind {
  LengthFit,
  LengthFill,
  LengthFixed,
  LengthPercent
}

struct Length {
  LengthKind kind;
  float value;
}

enum GuiDir {
  GuiColumn,
  GuiRow,
  GuiStack,
  GuiGrid
}

enum GuiAlign {
  GuiAlignDefault,
  GuiAlignStart,
  GuiAlignCenter,
  GuiAlignEnd,
  GuiAlignStretch
}

enum GuiJustify {
  GuiJustifyStart,
  GuiJustifyCenter,
  GuiJustifyEnd,
  GuiJustifyBetween,
  GuiJustifyAround
}

enum GuiElevation {
  GuiElevationNone,
  GuiElevationResting,
  GuiElevationRaised,
  GuiElevationFloating
}

enum GuiFont {
  GuiFontBody,
  GuiFontMedium,
  GuiFontDisplay,
  GuiFontMono,
  GuiFontIcons
}

enum GuiTextAlign {
  GuiTextStart,
  GuiTextCenter,
  GuiTextEnd
}

enum GuiKey {
  GuiKeyV,
  GuiKeyF,
  GuiKeyR,
  GuiKeyH,
  GuiKeyP,
  GuiKeyT,
  GuiKeyC,
  GuiKeyK,
  GuiKeyD,
  GuiKeyZ,
  GuiKeyEqual,
  GuiKeyMinus,
  GuiKeyDelete,
  GuiKeyBackspace,
  GuiKeyEscape,
  GuiKeyLeft,
  GuiKeyRight,
  GuiKeyUp,
  GuiKeyDown,
  GuiKeySpace,
  GuiKeyZero,
  GuiKeyOne,
  GuiKeyTwo,
  GuiKeyEnter,
  GuiKeyL,
  GuiKeyG,
  GuiKeyM,
  GuiKeyN
}

enum WidgetKind {
  WidgetWindow,
  WidgetBox,
  WidgetRow,
  WidgetColumn,
  WidgetStack,
  WidgetGrid,
  WidgetText,
  WidgetIcon,
  WidgetButton,
  WidgetCanvas,
  WidgetScroll,
  WidgetInput,
  WidgetScrub,
  WidgetCheckbox,
  WidgetSwitch,
  WidgetSlider,
  WidgetSelect,
  WidgetSpacer,
  WidgetDivider
}

// ---------------------------------------------------------------------------
// Lengths, colors, and small helpers
// ---------------------------------------------------------------------------

[user_literal] Length px(double value) => Length{kind: LengthKind::LengthFixed, value: value as float};

Length fill() => Length{kind: LengthKind::LengthFill, value: 1.0};
Length fit() => Length{kind: LengthKind::LengthFit, value: 0.0};
Length grow(double weight) => Length{kind: LengthKind::LengthFill, value: weight as float};
Length pct(double value) => Length{kind: LengthKind::LengthPercent, value: value as float};

Length gui::fill() => fill();
Length gui::fit() => fit();
Length gui::grow(double weight) => grow(weight);
Length gui::pct(double value) => pct(value);

Color gui::rgb(int r, int g, int b) =>
  Color{r: r as uchar, g: g as uchar, b: b as uchar, a: 255};

Color gui::rgba(int r, int g, int b, int a) =>
  Color{r: r as uchar, g: g as uchar, b: b as uchar, a: a as uchar};

Color gui::clear() => Color{r: 0, g: 0, b: 0, a: 0};

Color gui::mix(Color a, Color b, float t) {
  if (t <= 0.0) { return a; }
  if (t >= 1.0) { return b; }
  return Color{
    r: (a.r as float + (b.r as float - a.r as float) * t) as uchar,
    g: (a.g as float + (b.g as float - a.g as float) * t) as uchar,
    b: (a.b as float + (b.b as float - a.b as float) * t) as uchar,
    a: (a.a as float + (b.a as float - a.a as float) * t) as uchar
  };
}

Color gui::fade(Color color, int alpha) =>
  Color{r: color.r, g: color.g, b: color.b, a: alpha as uchar};

GuiFont gui::body() => GuiFont::GuiFontBody;
GuiFont gui::medium() => GuiFont::GuiFontMedium;
GuiFont gui::display() => GuiFont::GuiFontDisplay;
GuiFont gui::mono() => GuiFont::GuiFontMono;
GuiFont gui::icons() => GuiFont::GuiFontIcons;

float gui::minf(float a, float b) {
  if (a < b) { return a; }
  return b;
}

float gui::maxf(float a, float b) {
  if (a > b) { return a; }
  return b;
}

float gui::clampf(float value, float low, float high) {
  if (value < low) { return low; }
  if (value > high) { return high; }
  return value;
}

bool gui::hasPoint(Rect rect, float x, float y) {
  if (x < rect.x || x >= rect.x + rect.w) { return false; }
  if (y < rect.y || y >= rect.y + rect.h) { return false; }
  return true;
}

// ---------------------------------------------------------------------------
// Widget storage
// ---------------------------------------------------------------------------

type ClickHandler = () -> void;
type BuildHandler = () -> void;

struct Draw {
  Rect rect;
  void* user;
  void* ui;
}

type PaintHandler = () -> void;

struct Widget {
  WidgetKind kind;
  GuiDir dir;

  Length width;
  Length height;
  float minWidth;
  float maxWidth;
  float minHeight;
  float maxHeight;
  float padTop;
  float padRight;
  float padBottom;
  float padLeft;
  float gap;
  int columns;
  GuiAlign align;
  GuiJustify justify;
  Color bg;
  Color hoverBg;
  Color borderColor;
  float borderWidth;
  float radius;
  float radiusTl;
  float radiusTr;
  float radiusBr;
  float radiusBl;
  GuiElevation elevation;
  bool clip;
  bool scrollY;
  bool wrap;
  bool visible;
  bool disabled;
  bool selected;
  bool clickable;
  bool hiddenForLayout;

  const char* text;
  const char* label;
  const char* placeholder;
  const char* icon;
  float textSize;
  GuiFont font;
  Color textColor;
  GuiTextAlign textAlign;
  bool nowrap;
  const char* tooltip;
  const char* id;

  float* number;
  float numberMin;
  float numberMax;
  float numberStep;
  const char* numberSuffix;
  char* buffer;
  size_t bufferCap;
  bool* checked;
  char** selectItems;
  int selectCount;
  int* selectIndex;
  bool selectSearchable;

  int clickHandler;
  int clickTag;
  int paintHandler;
  int buildHandler;
  void* paintUser;

  Widget*[192] children;
  int childCount;
  char[48] autoId;
}

Widget[2048] widgetPool;
int widgetPoolCount = 0;
Widget windowWidget;

ClickHandler[2048] clickHandlers;
int clickHandlerCount = 0;
int guiClickTag = 0;
PaintHandler[256] paintHandlers;
int paintHandlerCount = 0;
BuildHandler[16] buildHandlers;
int buildHandlerCount = 0;

CuiApp guiApp = nullptr;
CuiCtx guiCtx = nullptr;
int guiWindowWidth = 1440;
int guiWindowHeight = 900;

void writeIndex(char* buffer, const char* prefix, int value) {
  int i = 0;
  while (prefix[i] != '\0' && i < 40) {
    buffer[i] = prefix[i];
    i = i + 1;
  }
  if (value < 0) {
    value = 0;
  }
  char[12] digits;
  int count = 0;
  if (value == 0) {
    digits[0] = '0';
    count = 1;
  } else {
    while (value > 0) {
      digits[count] = (48 + value % 10) as char;
      value = value / 10;
      count = count + 1;
    }
  }
  while (count > 0) {
    count = count - 1;
    buffer[i] = digits[count];
    i = i + 1;
  }
  buffer[i] = '\0';
}

void resetWidget(Widget* widget, WidgetKind kind, int index) {
  widget.kind = kind;
  widget.dir = GuiDir::GuiColumn;
  widget.width = fit();
  widget.height = fit();
  widget.minWidth = 0.0;
  widget.maxWidth = 0.0;
  widget.minHeight = 0.0;
  widget.maxHeight = 0.0;
  widget.padTop = 0.0;
  widget.padRight = 0.0;
  widget.padBottom = 0.0;
  widget.padLeft = 0.0;
  widget.gap = 0.0;
  widget.columns = 2;
  widget.align = GuiAlign::GuiAlignDefault;
  widget.justify = GuiJustify::GuiJustifyStart;
  widget.bg = gui::clear();
  widget.hoverBg = gui::clear();
  widget.borderColor = gui::clear();
  widget.borderWidth = 0.0;
  widget.radius = 0.0;
  widget.radiusTl = -1.0;
  widget.radiusTr = -1.0;
  widget.radiusBr = -1.0;
  widget.radiusBl = -1.0;
  widget.elevation = GuiElevation::GuiElevationNone;
  widget.clip = false;
  widget.scrollY = false;
  widget.wrap = false;
  widget.visible = true;
  widget.disabled = false;
  widget.selected = false;
  widget.clickable = false;
  widget.hiddenForLayout = false;
  widget.text = nullptr;
  widget.label = nullptr;
  widget.placeholder = nullptr;
  widget.icon = nullptr;
  widget.textSize = 11.0;
  widget.font = GuiFont::GuiFontBody;
  widget.textColor = gui::rgb(28, 28, 30);
  widget.textAlign = GuiTextAlign::GuiTextStart;
  widget.nowrap = true;
  widget.tooltip = nullptr;
  widget.number = nullptr;
  widget.numberMin = 0.0;
  widget.numberMax = 100.0;
  widget.numberStep = 1.0;
  widget.numberSuffix = nullptr;
  widget.buffer = nullptr;
  widget.bufferCap = 0;
  widget.checked = nullptr;
  widget.selectItems = nullptr;
  widget.selectCount = 0;
  widget.selectIndex = nullptr;
  widget.selectSearchable = false;
  widget.clickHandler = -1;
  widget.clickTag = 0;
  widget.paintHandler = -1;
  widget.buildHandler = -1;
  widget.paintUser = nullptr;
  widget.childCount = 0;
  writeIndex(&widget.autoId[0], "gw-", index);
  widget.id = &widget.autoId[0];
}

Widget* allocWidget(WidgetKind kind) {
  if (widgetPoolCount >= 2048) {
    widgetPoolCount = 2047;
  }
  Widget* widget = &widgetPool[widgetPoolCount];
  resetWidget(widget, kind, widgetPoolCount);
  widgetPoolCount = widgetPoolCount + 1;
  return widget;
}

int registerClick(ClickHandler handler) {
  if (clickHandlerCount >= 2048) {
    clickHandlerCount = 2047;
  }
  clickHandlers[clickHandlerCount] = handler;
  clickHandlerCount = clickHandlerCount + 1;
  return clickHandlerCount - 1;
}

int registerPaint(PaintHandler handler) {
  if (paintHandlerCount >= 256) {
    paintHandlerCount = 255;
  }
  paintHandlers[paintHandlerCount] = handler;
  paintHandlerCount = paintHandlerCount + 1;
  return paintHandlerCount - 1;
}

int registerBuild(BuildHandler handler) {
  if (buildHandlerCount >= 16) {
    buildHandlerCount = 15;
  }
  buildHandlers[buildHandlerCount] = handler;
  buildHandlerCount = buildHandlerCount + 1;
  return buildHandlerCount - 1;
}

void invokeClick(int index) {
  if (index < 0 || index >= clickHandlerCount) {
    return;
  }
  ClickHandler handler = clickHandlers[index];
  handler();
}

void invokeBuild(int index) {
  if (index < 0 || index >= buildHandlerCount) {
    return;
  }
  BuildHandler handler = buildHandlers[index];
  handler();
}

// ---------------------------------------------------------------------------
// Static constructors
// ---------------------------------------------------------------------------

struct Window {}
struct BBox {}
struct Row {}
struct Column {}
struct Stack {}
struct Grid {}
struct Text {}
struct Icon {}
struct Button {}
struct Canvas {}
struct Scroll {}
struct Input {}
struct Scrub {}
struct Checkbox {}
struct Switch {}
struct Slider {}
struct Select {}
struct Spacer {}
struct Divider {}
struct gui {}

Widget* Window::new() {
  resetWidget(&windowWidget, WidgetKind::WidgetWindow, 0);
  windowWidget.width = px(1200.0);
  windowWidget.height = px(800.0);
  windowWidget.text = "Glang GUI";
  windowWidget.id = "gui-window";
  return &windowWidget;
}

Widget* BBox::new() => allocWidget(WidgetKind::WidgetBox);
Widget* Column::new() => allocWidget(WidgetKind::WidgetColumn);

Widget* Row::new() {
  Widget* widget = allocWidget(WidgetKind::WidgetRow);
  widget.dir = GuiDir::GuiRow;
  return widget;
}

Widget* Stack::new() {
  Widget* widget = allocWidget(WidgetKind::WidgetStack);
  widget.dir = GuiDir::GuiStack;
  return widget;
}

Widget* Grid::new() {
  Widget* widget = allocWidget(WidgetKind::WidgetGrid);
  widget.dir = GuiDir::GuiGrid;
  return widget;
}

Widget* Text::new() => allocWidget(WidgetKind::WidgetText);
Widget* Button::new() => allocWidget(WidgetKind::WidgetButton);
Widget* Canvas::new() => allocWidget(WidgetKind::WidgetCanvas);
Widget* Scroll::new() => allocWidget(WidgetKind::WidgetScroll);
Widget* Input::new() => allocWidget(WidgetKind::WidgetInput);
Widget* Scrub::new() => allocWidget(WidgetKind::WidgetScrub);
Widget* Checkbox::new() => allocWidget(WidgetKind::WidgetCheckbox);
Widget* Switch::new() => allocWidget(WidgetKind::WidgetSwitch);
Widget* Slider::new() => allocWidget(WidgetKind::WidgetSlider);
Widget* Select::new() => allocWidget(WidgetKind::WidgetSelect);
Widget* Spacer::new() => allocWidget(WidgetKind::WidgetSpacer);
Widget* Divider::new() {
  Widget* widget = allocWidget(WidgetKind::WidgetDivider);
  widget.width = fill();
  widget.height = px(1.0);
  return widget;
}

Widget* Icon::new() {
  Widget* widget = allocWidget(WidgetKind::WidgetIcon);
  widget.textSize = 14.0;
  return widget;
}

// ---------------------------------------------------------------------------
// Builders
// ---------------------------------------------------------------------------

Widget* set_id(Widget* self, const char* id) {
  self.id = id;
  return self;
}

Widget* set_size(Widget* self, Length width, Length height) {
  self.width = width;
  self.height = height;
  return self;
}

Widget* set_width(Widget* self, Length width) {
  self.width = width;
  return self;
}

Widget* set_height(Widget* self, Length height) {
  self.height = height;
  return self;
}

Widget* set_min_size(Widget* self, float width, float height) {
  self.minWidth = width;
  self.minHeight = height;
  return self;
}

Widget* set_max_size(Widget* self, float width, float height) {
  self.maxWidth = width;
  self.maxHeight = height;
  return self;
}

Widget* set_padding(Widget* self, float pad) {
  self.padTop = pad;
  self.padRight = pad;
  self.padBottom = pad;
  self.padLeft = pad;
  return self;
}

Widget* set_padding_xy(Widget* self, float x, float y) {
  self.padLeft = x;
  self.padRight = x;
  self.padTop = y;
  self.padBottom = y;
  return self;
}

Widget* set_padding_each(Widget* self, float top, float right, float bottom, float left) {
  self.padTop = top;
  self.padRight = right;
  self.padBottom = bottom;
  self.padLeft = left;
  return self;
}

Widget* set_pad_top(Widget* self, float pad) { self.padTop = pad; return self; }
Widget* set_pad_right(Widget* self, float pad) { self.padRight = pad; return self; }
Widget* set_pad_bottom(Widget* self, float pad) { self.padBottom = pad; return self; }
Widget* set_pad_left(Widget* self, float pad) { self.padLeft = pad; return self; }

Widget* set_gap(Widget* self, float gap) {
  self.gap = gap;
  return self;
}

Widget* set_columns(Widget* self, int columns) {
  self.columns = columns;
  return self;
}

Widget* set_align(Widget* self, GuiAlign align) {
  self.align = align;
  return self;
}

Widget* set_justify(Widget* self, GuiJustify justify) {
  self.justify = justify;
  return self;
}

Widget* set_bg(Widget* self, Color color) {
  self.bg = color;
  return self;
}

Widget* set_hover_bg(Widget* self, Color color) {
  self.hoverBg = color;
  return self;
}

Widget* set_border(Widget* self, float width, Color color) {
  self.borderWidth = width;
  self.borderColor = color;
  return self;
}

Widget* set_border_width(Widget* self, float width) {
  self.borderWidth = width;
  return self;
}

Widget* set_border_color(Widget* self, Color color) {
  self.borderColor = color;
  return self;
}

Widget* set_radius(Widget* self, float radius) {
  self.radius = radius;
  return self;
}

Widget* set_corners(Widget* self, float tl, float tr, float br, float bl) {
  self.radiusTl = tl;
  self.radiusTr = tr;
  self.radiusBr = br;
  self.radiusBl = bl;
  return self;
}

Widget* set_elevation(Widget* self, GuiElevation elevation) {
  self.elevation = elevation;
  return self;
}

Widget* set_clip(Widget* self, bool clip) {
  self.clip = clip;
  return self;
}

Widget* set_scroll(Widget* self, bool scrollY) {
  self.scrollY = scrollY;
  return self;
}

Widget* set_wrap(Widget* self, bool wrap) {
  self.wrap = wrap;
  return self;
}

Widget* set_text(Widget* self, const char* text) {
  self.text = text;
  return self;
}

Widget* set_label(Widget* self, const char* label) {
  self.label = label;
  return self;
}

Widget* set_placeholder(Widget* self, const char* placeholder) {
  self.placeholder = placeholder;
  return self;
}

Widget* set_text_size(Widget* self, float size) {
  self.textSize = size;
  return self;
}

Widget* set_text_color(Widget* self, Color color) {
  self.textColor = color;
  return self;
}

Widget* set_text_align(Widget* self, GuiTextAlign align) {
  self.textAlign = align;
  return self;
}

Widget* set_text_wrap(Widget* self, bool wrap) {
  self.nowrap = !wrap;
  return self;
}

Widget* set_font(Widget* self, GuiFont font) {
  self.font = font;
  return self;
}

Widget* set_icon(Widget* self, const char* icon) {
  self.icon = icon;
  return self;
}

Widget* on_click(Widget* self, ClickHandler handler) {
  self.clickHandler = registerClick(handler);
  self.clickable = true;
  return self;
}

Widget* on_click_tag(Widget* self, int tag, ClickHandler handler) {
  self.clickTag = tag;
  self.clickHandler = registerClick(handler);
  self.clickable = true;
  return self;
}

Widget* on_paint(Widget* self, PaintHandler handler) {
  self.paintHandler = registerPaint(handler);
  return self;
}

Widget* on_build(Widget* self, BuildHandler handler) {
  self.buildHandler = registerBuild(handler);
  return self;
}

Widget* set_value(Widget* self, float* value, float low, float high) {
  self.number = value;
  self.numberMin = low;
  self.numberMax = high;
  return self;
}

Widget* set_step(Widget* self, float step) {
  self.numberStep = step;
  return self;
}

Widget* set_suffix(Widget* self, const char* suffix) {
  self.numberSuffix = suffix;
  return self;
}

Widget* set_buffer(Widget* self, char* buffer, size_t cap) {
  self.buffer = buffer;
  self.bufferCap = cap;
  return self;
}

Widget* set_checked(Widget* self, bool* value) {
  self.checked = value;
  return self;
}

Widget* set_options(Widget* self, char** items, int count, int* index) {
  self.selectItems = items;
  self.selectCount = count;
  self.selectIndex = index;
  return self;
}

Widget* set_searchable(Widget* self, bool searchable) {
  self.selectSearchable = searchable;
  return self;
}

Widget* set_selected(Widget* self, bool selected) {
  self.selected = selected;
  return self;
}

Widget* set_disabled(Widget* self, bool disabled) {
  self.disabled = disabled;
  return self;
}

Widget* set_visible(Widget* self, bool visible) {
  self.visible = visible;
  return self;
}

Widget* set_tooltip(Widget* self, const char* tooltip) {
  self.tooltip = tooltip;
  return self;
}

Widget* set_title(Widget* self, const char* title) {
  self.text = title;
  return self;
}

Widget* add(Widget* self, Widget* child) {
  if (child == nullptr) {
    return self;
  }
  if (self.childCount >= 192) {
    return self;
  }
  self.children[self.childCount] = child;
  self.childCount = self.childCount + 1;
  return self;
}

Widget* clear(Widget* self) {
  self.childCount = 0;
  return self;
}

// ---------------------------------------------------------------------------
// CUI layout mapping
// ---------------------------------------------------------------------------

CuiColor toCuiColor(Color color) => CuiColor{r: color.r, g: color.g, b: color.b, a: color.a};

CuiSize toCuiSize(Length length) {
  if (length.kind == LengthKind::LengthFill) {
    return CuiSize{kind: CuiSizeKind::Grow, value: length.value};
  }
  if (length.kind == LengthKind::LengthFixed) {
    return CuiSize{kind: CuiSizeKind::Fixed, value: length.value};
  }
  if (length.kind == LengthKind::LengthPercent) {
    return CuiSize{kind: CuiSizeKind::Percent, value: length.value};
  }
  return CuiSize{kind: CuiSizeKind::Fit, value: 0.0};
}

CuiDir toCuiDir(GuiDir dir) {
  if (dir == GuiDir::GuiRow) { return CuiDir::Row; }
  if (dir == GuiDir::GuiStack) { return CuiDir::Stack; }
  if (dir == GuiDir::GuiGrid) { return CuiDir::Grid; }
  return CuiDir::Column;
}

CuiAlign toCuiAlign(GuiAlign align) {
  if (align == GuiAlign::GuiAlignStart) { return CuiAlign::Start; }
  if (align == GuiAlign::GuiAlignCenter) { return CuiAlign::Center; }
  if (align == GuiAlign::GuiAlignEnd) { return CuiAlign::End; }
  if (align == GuiAlign::GuiAlignStretch) { return CuiAlign::Stretch; }
  return CuiAlign::Default;
}

CuiJustify toCuiJustify(GuiJustify justify) {
  if (justify == GuiJustify::GuiJustifyCenter) { return CuiJustify::JustifyCenter; }
  if (justify == GuiJustify::GuiJustifyEnd) { return CuiJustify::JustifyEnd; }
  if (justify == GuiJustify::GuiJustifyBetween) { return CuiJustify::JustifyBetween; }
  if (justify == GuiJustify::GuiJustifyAround) { return CuiJustify::JustifyAround; }
  return CuiJustify::JustifyStart;
}

CuiElevation toCuiElevation(GuiElevation elevation) {
  if (elevation == GuiElevation::GuiElevationResting) { return CuiElevation::Resting; }
  if (elevation == GuiElevation::GuiElevationRaised) { return CuiElevation::Raised; }
  if (elevation == GuiElevation::GuiElevationFloating) { return CuiElevation::Floating; }
  return CuiElevation::ElevationNone;
}

int toCuiFont(GuiFont font) {
  return font as int;
}

CuiFont toCuiEnumFont(GuiFont font) {
  if (font == GuiFont::GuiFontMedium) { return CuiFont::FontMedium; }
  if (font == GuiFont::GuiFontDisplay) { return CuiFont::FontDisplay; }
  if (font == GuiFont::GuiFontMono) { return CuiFont::FontMono; }
  if (font == GuiFont::GuiFontIcons) { return CuiFont::FontIcons; }
  return CuiFont::FontBody;
}

CuiTextAlign toCuiTextAlign(GuiTextAlign align) {
  if (align == GuiTextAlign::GuiTextCenter) { return CuiTextAlign::TextCenter; }
  if (align == GuiTextAlign::GuiTextEnd) { return CuiTextAlign::TextEnd; }
  return CuiTextAlign::TextStart;
}

CuiBox boxOf(Widget* widget) {
  CuiBox box = CuiBox{};
  box.id = widget.id;
  box.dir = toCuiDir(widget.dir);
  box.width = toCuiSize(widget.width);
  box.height = toCuiSize(widget.height);
  box.min_width = widget.minWidth;
  box.max_width = widget.maxWidth;
  box.min_height = widget.minHeight;
  box.max_height = widget.maxHeight;
  box.pad_top = widget.padTop;
  box.pad_right = widget.padRight;
  box.pad_bottom = widget.padBottom;
  box.pad_left = widget.padLeft;
  box.gap = widget.gap;
  box.columns = widget.columns;
  box.wrap = widget.wrap;
  box.align = toCuiAlign(widget.align);
  box.justify = toCuiJustify(widget.justify);
  box.bg = toCuiColor(widget.bg);
  box.border_color = toCuiColor(widget.borderColor);
  box.border = widget.borderWidth;
  box.radius = widget.radius;
  box.radius_tl = widget.radiusTl;
  box.radius_tr = widget.radiusTr;
  box.radius_br = widget.radiusBr;
  box.radius_bl = widget.radiusBl;
  box.elevation = toCuiElevation(widget.elevation);
  box.scroll_y = widget.scrollY;
  box.clip = widget.clip;
  return box;
}

bool isHovered(CuiCtx ui, Widget* widget) {
  if (widget.id == nullptr) {
    return false;
  }
  CuiId id = cui_make_id(ui, widget.id);
  CuiRect rect = cui_get_rect(ui, id);
  CuiVec2 mouse = cui_mouse_pos(ui);
  return mouse.x >= rect.x && mouse.x < rect.x + rect.w &&
         mouse.y >= rect.y && mouse.y < rect.y + rect.h;
}

Color buttonBg(CuiCtx ui, Widget* widget) {
  if (isHovered(ui, widget) && widget.hoverBg.a > 0) {
    return widget.hoverBg;
  }
  return widget.bg;
}

void emitWidgets(CuiCtx ui, Widget* parent) {
  for (int i = 0; i < parent.childCount; i = i + 1) {
    emitWidget(ui, parent.children[i]);
  }
}

void emitBox(Widget* widget, CuiCtx ui, bool isButton) {
  CuiBox box = boxOf(widget);
  box.bg = toCuiColor(buttonBg(ui, widget));
  if (isButton) {
    box.dir = CuiDir::Row;
    if (widget.align == GuiAlign::GuiAlignDefault) {
      box.align = CuiAlign::Center;
    }
    if (widget.justify == GuiJustify::GuiJustifyStart && widget.childCount == 0) {
      box.justify = CuiJustify::JustifyCenter;
    }
  }
  CuiId id = cui_box_begin(ui, &box);
  if (isButton && widget.icon != nullptr) {
    cui_icon(ui, widget.icon, widget.textSize, toCuiColor(widget.textColor));
  }
  if (isButton && widget.text != nullptr) {
    CuiTextOpts text = CuiTextOpts{
      font: toCuiFont(widget.font),
      size: widget.textSize,
      color: toCuiColor(widget.textColor),
      align: toCuiTextAlign(widget.textAlign),
      nowrap: widget.nowrap
    };
    cui_text_ex(ui, widget.text, &text);
  }
  emitWidgets(ui, widget);
  cui_box_end(ui);
  CuiVec2 mouse = cui_mouse_pos(ui);
  CuiRect rect = cui_get_rect(ui, id);
  bool hovered = mouse.x >= rect.x && mouse.x < rect.x + rect.w &&
                 mouse.y >= rect.y && mouse.y < rect.y + rect.h;
  if (hovered && widget.tooltip != nullptr) {
    cui_tooltip(ui, widget.tooltip);
  }
  bool clicked = hovered && cui_mouse_clicked(ui, CuiMouseButton::MouseLeft);
  if (clicked) {
    guiClickTag = widget.clickTag;
    invokeClick(widget.clickHandler);
  }
}

void emitText(Widget* widget, CuiCtx ui) {
  if (widget.text == nullptr) {
    return;
  }
  CuiTextOpts opts = CuiTextOpts{
    font: toCuiFont(widget.font),
    size: widget.textSize,
    color: toCuiColor(widget.textColor),
    align: toCuiTextAlign(widget.textAlign),
    nowrap: widget.nowrap,
    width: toCuiSize(widget.width)
  };
  cui_text_ex(ui, widget.text, &opts);
}

void emitIcon(Widget* widget, CuiCtx ui) {
  if (widget.icon == nullptr) {
    return;
  }
  cui_icon(ui, widget.icon, widget.textSize, toCuiColor(widget.textColor));
}

void emitScroll(Widget* widget, CuiCtx ui) {
  CuiScrollOpts opts = CuiScrollOpts{};
  opts.id = widget.id;
  opts.width = toCuiSize(widget.width);
  opts.height = toCuiSize(widget.height);
  opts.pad = widget.padTop;
  opts.gap = widget.gap;
  cui_scroll_begin(ui, &opts);
  emitWidgets(ui, widget);
  cui_scroll_end(ui);
}

void emitInput(Widget* widget, CuiCtx ui) {
  if (widget.buffer == nullptr) {
    return;
  }
  CuiInputOpts opts = CuiInputOpts{};
  opts.label = widget.label;
  opts.placeholder = widget.placeholder;
  opts.width = toCuiSize(widget.width);
  opts.height = widget.height.value;
  cui_input_ex(ui, widget.id, widget.buffer, widget.bufferCap, &opts);
}

void emitScrub(Widget* widget, CuiCtx ui) {
  if (widget.number == nullptr) {
    return;
  }
  CuiScrubOpts opts = CuiScrubOpts{};
  opts.step = widget.numberStep;
  opts.suffix = widget.numberSuffix;
  opts.width = toCuiSize(widget.width);
  if (widget.id != nullptr) { cui_push_id(ui, widget.id); }
  cui_scrub_ex(ui, widget.text, widget.number, widget.numberMin, widget.numberMax, &opts);
  if (widget.id != nullptr) { cui_pop_id(ui); }
}

void emitCheckbox(Widget* widget, CuiCtx ui) {
  if (widget.checked == nullptr) {
    return;
  }
  CuiCheckOpts opts = CuiCheckOpts{};
  if (widget.id != nullptr) { cui_push_id(ui, widget.id); }
  cui_checkbox_ex(ui, widget.text, widget.checked, &opts);
  if (widget.id != nullptr) { cui_pop_id(ui); }
}

void emitSwitch(Widget* widget, CuiCtx ui) {
  if (widget.checked == nullptr) {
    return;
  }
  CuiCheckOpts opts = CuiCheckOpts{};
  opts.disabled = widget.disabled;
  if (widget.id != nullptr) { cui_push_id(ui, widget.id); }
  cui_switch_ex(ui, widget.text, widget.checked, &opts);
  if (widget.id != nullptr) { cui_pop_id(ui); }
}

void emitSlider(Widget* widget, CuiCtx ui) {
  if (widget.number == nullptr) {
    return;
  }
  CuiSliderOpts opts = CuiSliderOpts{};
  opts.step = widget.numberStep;
  opts.show_value = true;
  opts.disabled = widget.disabled;
  opts.width = toCuiSize(widget.width);
  if (widget.id != nullptr) { cui_push_id(ui, widget.id); }
  cui_slider_ex(ui, widget.text, widget.number, widget.numberMin, widget.numberMax, &opts);
  if (widget.id != nullptr) { cui_pop_id(ui); }
}

void emitSelect(Widget* widget, CuiCtx ui) {
  if (widget.selectItems == nullptr || widget.selectIndex == nullptr || widget.selectCount <= 0) {
    return;
  }
  CuiSelectOpts opts = CuiSelectOpts{};
  opts.label = widget.label;
  opts.placeholder = widget.placeholder;
  opts.searchable = widget.selectSearchable;
  opts.disabled = widget.disabled;
  opts.width = toCuiSize(widget.width);
  cui_select_ex(ui, widget.id, widget.selectItems, widget.selectCount, widget.selectIndex, &opts);
}

void emitCanvas(Widget* widget, CuiCtx ui) {
  cui_push_disabled(ui, true);
  cui_canvas(ui, widget.id, toCuiSize(widget.width), toCuiSize(widget.height),
             guiPaintDispatch, widget, 0);
  cui_pop_disabled(ui);
}

void emitWidget(CuiCtx ui, Widget* widget) {
  if (widget == nullptr || !widget.visible) {
    return;
  }
  if (widget.disabled) {
    cui_push_disabled(ui, true);
  }

  if (widget.kind == WidgetKind::WidgetText) {
    emitText(widget, ui);
  } else if (widget.kind == WidgetKind::WidgetIcon) {
    emitIcon(widget, ui);
  } else if (widget.kind == WidgetKind::WidgetSpacer) {
    cui_spacer(ui);
  } else if (widget.kind == WidgetKind::WidgetDivider) {
    CuiBox box = CuiBox{};
    box.width = toCuiSize(widget.width);
    box.height = toCuiSize(widget.height);
    box.bg = toCuiColor(widget.bg);
    cui_box_begin(ui, &box);
    cui_box_end(ui);
  } else if (widget.kind == WidgetKind::WidgetScroll) {
    emitScroll(widget, ui);
  } else if (widget.kind == WidgetKind::WidgetInput) {
    emitInput(widget, ui);
  } else if (widget.kind == WidgetKind::WidgetScrub) {
    emitScrub(widget, ui);
  } else if (widget.kind == WidgetKind::WidgetCheckbox) {
    emitCheckbox(widget, ui);
  } else if (widget.kind == WidgetKind::WidgetSwitch) {
    emitSwitch(widget, ui);
  } else if (widget.kind == WidgetKind::WidgetSlider) {
    emitSlider(widget, ui);
  } else if (widget.kind == WidgetKind::WidgetSelect) {
    emitSelect(widget, ui);
  } else if (widget.kind == WidgetKind::WidgetCanvas) {
    emitCanvas(widget, ui);
  } else if (widget.kind == WidgetKind::WidgetButton) {
    emitBox(widget, ui, true);
  } else {
    emitBox(widget, ui, false);
  }

  if (widget.disabled) {
    cui_pop_disabled(ui);
  }
}

// The C-ABI paint adapter. `user` is the Widget pointer because canvases pass
// `user` through unchanged when `user_size` is zero.
Draw guiDrawContext;
bool guiDrawActive = false;

void guiPaintDispatch(CuiCtx ui, CuiRect rect, void* user) {
  Widget* widget = user as Widget*;
  if (widget.paintHandler < 0 || widget.paintHandler >= paintHandlerCount) {
    return;
  }
  guiDrawContext = Draw{
    rect: Rect{ x: rect.x, y: rect.y, w: rect.w, h: rect.h },
    user: widget.paintUser,
    ui: ui
  };
  guiDrawActive = true;
  PaintHandler handler = paintHandlers[widget.paintHandler];
  handler();
  guiDrawActive = false;
}

Draw* gui::paintDraw() => &guiDrawContext;
int gui::clickTag() => guiClickTag;

// ---------------------------------------------------------------------------
// Drawing helpers for custom canvases
// ---------------------------------------------------------------------------

void gui::rect(Draw* draw, float x, float y, float w, float h, float radius, Color fill) {
  CuiCorners corners = CuiCorners{tl: radius, tr: radius, br: radius, bl: radius};
  cui_draw_rect(draw.ui, CuiRect{x: x, y: y, w: w, h: h}, corners, toCuiColor(fill));
}

void gui::rectBorder(Draw* draw, float x, float y, float w, float h,
                     float radius, Color fill, Color border, float borderWidth) {
  CuiCorners corners = CuiCorners{tl: radius, tr: radius, br: radius, bl: radius};
  cui_draw_rect_border(draw.ui, CuiRect{x: x, y: y, w: w, h: h}, corners,
                       toCuiColor(fill), toCuiColor(border), borderWidth);
}

void gui::line(Draw* draw, float x0, float y0, float x1, float y1,
               float thickness, Color color) {
  cui_draw_line(draw.ui, CuiVec2{x: x0, y: y0}, CuiVec2{x: x1, y: y1},
                thickness, toCuiColor(color));
}

void gui::circle(Draw* draw, float cx, float cy, float radius, Color color) {
  CuiCorners corners = CuiCorners{tl: radius, tr: radius, br: radius, bl: radius};
  cui_draw_rect(draw.ui, CuiRect{x: cx - radius, y: cy - radius,
                                 w: (radius * 2.0) as float, h: (radius * 2.0) as float},
                corners, toCuiColor(color));
}

void gui::arc(Draw* draw, float cx, float cy, float radius,
              float a0, float a1, float thickness, Color color) {
  cui_draw_arc(draw.ui, CuiVec2{x: cx, y: cy}, radius, a0, a1,
               thickness, toCuiColor(color));
}

void gui::text(Draw* draw, const char* value, float x, float y,
               float size, GuiFont font, Color color) {
  cui_draw_text(draw.ui, toCuiEnumFont(font), size, CuiVec2{x: x, y: y},
                toCuiColor(color), value, -1);
}

void gui::icon(Draw* draw, const char* glyph, float x, float y,
               float size, Color color) {
  cui_draw_icon(draw.ui, glyph, CuiRect{x: x, y: y, w: size, h: size},
                size, toCuiColor(color));
}

float gui::textWidth(Draw* draw, const char* value, float size, GuiFont font) {
  CuiTextMetrics metrics = cui_measure_text(draw.ui, toCuiEnumFont(font), size, value, -1);
  return metrics.width;
}

float gui::textHeight(Draw* draw, const char* value, float size, GuiFont font) {
  CuiTextMetrics metrics = cui_measure_text(draw.ui, toCuiEnumFont(font), size, value, -1);
  return metrics.height;
}

void gui::pushClip(Draw* draw, float x, float y, float w, float h) {
  cui_push_clip(draw.ui, CuiRect{x: x, y: y, w: w, h: h});
}

void gui::popClip(Draw* draw) {
  cui_pop_clip(draw.ui);
}

void gui::redraw(Draw* draw) {
  cui_request_redraw(draw.ui);
}

// ---------------------------------------------------------------------------
// Input and app helpers
// ---------------------------------------------------------------------------

float gui::mouseX() {
  if (guiCtx == nullptr) { return 0.0; }
  return cui_mouse_pos(guiCtx).x;
}

float gui::mouseY() {
  if (guiCtx == nullptr) { return 0.0; }
  return cui_mouse_pos(guiCtx).y;
}

bool gui::mouseDown() {
  if (guiCtx == nullptr) { return false; }
  return cui_mouse_down(guiCtx, CuiMouseButton::MouseLeft);
}

bool gui::mouseClicked() {
  if (guiCtx == nullptr) { return false; }
  return cui_mouse_clicked(guiCtx, CuiMouseButton::MouseLeft);
}

bool gui::middleDown() {
  if (guiCtx == nullptr) { return false; }
  return cui_mouse_down(guiCtx, CuiMouseButton::MouseMiddle);
}

CuiKey toCuiKey(GuiKey key) {
  if (key == GuiKey::GuiKeyV) { return CuiKey::KeyV; }
  if (key == GuiKey::GuiKeyF) { return CuiKey::KeyF; }
  if (key == GuiKey::GuiKeyR) { return CuiKey::KeyR; }
  if (key == GuiKey::GuiKeyH) { return CuiKey::KeyH; }
  if (key == GuiKey::GuiKeyP) { return CuiKey::KeyP; }
  if (key == GuiKey::GuiKeyT) { return CuiKey::KeyT; }
  if (key == GuiKey::GuiKeyC) { return CuiKey::KeyC; }
  if (key == GuiKey::GuiKeyK) { return CuiKey::KeyK; }
  if (key == GuiKey::GuiKeyD) { return CuiKey::KeyD; }
  if (key == GuiKey::GuiKeyZ) { return CuiKey::KeyZ; }
  if (key == GuiKey::GuiKeyL) { return CuiKey::KeyL; }
  if (key == GuiKey::GuiKeyG) { return CuiKey::KeyG; }
  if (key == GuiKey::GuiKeyM) { return CuiKey::KeyM; }
  if (key == GuiKey::GuiKeyN) { return CuiKey::KeyN; }
  if (key == GuiKey::GuiKeyEqual) { return CuiKey::KeyEqual; }
  if (key == GuiKey::GuiKeyMinus) { return CuiKey::KeyMinus; }
  if (key == GuiKey::GuiKeyDelete) { return CuiKey::KeyDelete; }
  if (key == GuiKey::GuiKeyBackspace) { return CuiKey::KeyBackspace; }
  if (key == GuiKey::GuiKeyEscape) { return CuiKey::KeyEscape; }
  if (key == GuiKey::GuiKeyEnter) { return CuiKey::KeyEnter; }
  if (key == GuiKey::GuiKeyLeft) { return CuiKey::KeyLeft; }
  if (key == GuiKey::GuiKeyRight) { return CuiKey::KeyRight; }
  if (key == GuiKey::GuiKeyUp) { return CuiKey::KeyUp; }
  if (key == GuiKey::GuiKeyDown) { return CuiKey::KeyDown; }
  if (key == GuiKey::GuiKeySpace) { return CuiKey::KeySpace; }
  if (key == GuiKey::GuiKeyZero) { return CuiKey::Key0; }
  if (key == GuiKey::GuiKeyOne) { return CuiKey::Key1; }
  if (key == GuiKey::GuiKeyTwo) { return CuiKey::Key2; }
  return CuiKey::KeyNone;
}

bool gui::keyPressed(GuiKey key) {
  if (guiCtx == nullptr) { return false; }
  CuiKey ck = toCuiKey(key);
  if (ck == CuiKey::KeyNone) { return false; }
  return cui_key_pressed(guiCtx, ck);
}

bool gui::keyDown(GuiKey key) {
  if (guiCtx == nullptr) { return false; }
  CuiKey ck = toCuiKey(key);
  if (ck == CuiKey::KeyNone) { return false; }
  return cui_key_down(guiCtx, ck);
}

Rect gui::widgetRect(const char* id) {
  if (guiCtx == nullptr || id == nullptr) {
    return Rect{x: 0.0, y: 0.0, w: 0.0, h: 0.0};
  }
  CuiRect r = cui_get_rect(guiCtx, cui_make_id(guiCtx, id));
  return Rect{x: r.x, y: r.y, w: r.w, h: r.h};
}

bool gui::wantsKeyboard() {
  if (guiCtx == nullptr) { return false; }
  return cui_wants_keyboard(guiCtx);
}

int gui::windowWidth() => guiWindowWidth;
int gui::windowHeight() => guiWindowHeight;

void gui::setTheme(bool dark) {
  if (guiCtx == nullptr) { return; }
  if (dark) {
    cui_set_theme(guiCtx, CuiThemeMode::Dark);
  } else {
    cui_set_theme(guiCtx, CuiThemeMode::Light);
  }
}

void gui::minimize() {
  if (guiApp != nullptr) { cui_app_minimize(guiApp); }
}

void gui::toggleMaximize() {
  if (guiApp == nullptr) { return; }
  if (cui_app_window_state(guiApp) == CuiWindowState::Maximized) {
    cui_app_restore(guiApp);
  } else {
    cui_app_maximize(guiApp);
  }
}

void gui::quit() {
  if (guiApp != nullptr) { cui_app_quit(guiApp); }
}

void gui::requestRedraw() {
  if (guiCtx != nullptr) { cui_request_redraw(guiCtx); }
}

void gui::toast(const char* title, const char* description) {
  if (guiCtx == nullptr) { return; }
  CuiToastOpts opts = CuiToastOpts{description: description, tone: CuiTone::ToneSuccess, duration: 2.2};
  cui_toast_ex(guiCtx, title, &opts);
}

Rect gui::canvasRect() {
  return Rect{
    x: 0.0,
    y: 0.0,
    w: guiWindowWidth as float,
    h: guiWindowHeight as float
  };
}

// ---------------------------------------------------------------------------
// Runtime
// ---------------------------------------------------------------------------

void resetFrame(Widget* window) {
  widgetPoolCount = 0;
  clickHandlerCount = 0;
  paintHandlerCount = 0;
  window.childCount = 0;
}

int sizeOfWindow(Length length, int fallback) {
  if (length.kind == LengthKind::LengthFixed) {
    return length.value as int;
  }
  return fallback;
}

int gui::run(Widget* window) {
  if (window == nullptr) {
    return 1;
  }

  int width = sizeOfWindow(window.width, 1200);
  int height = sizeOfWindow(window.height, 800);
  if (width < 320) { width = 320; }
  if (height < 240) { height = 240; }
  guiWindowWidth = width;
  guiWindowHeight = height;

  bool smoke = getenv("CUI_SMOKE") != nullptr;
  CuiAppDesc desc = CuiAppDesc{
    title: window.text,
    width: width,
    height: height,
    min_width: window.minWidth as int,
    min_height: window.minHeight as int,
    theme: CuiThemeMode::Light,
    accent: CuiAccent::Green,
    hidden: smoke,
    continuous: smoke
  };

  CuiApp app = cui_app_create(&desc);
  if (app == nullptr) {
    return 1;
  }
  defer cui_app_destroy(app);
  guiApp = app;

  int frames = 0;
  while (cui_app_frame(app)) {
    CuiCtx ui = cui_app_ui(app);
    guiCtx = ui;

    CuiVec2 vp = cui_viewport_size(ui);
    if (vp.x > 0.0 && vp.y > 0.0) {
      guiWindowWidth = vp.x as int;
      guiWindowHeight = vp.y as int;
    }

    if (window.buildHandler >= 0) {
      resetFrame(window);
      invokeBuild(window.buildHandler);
    }

    CuiBox root = CuiBox{};
    root.width = CuiSize{kind: CuiSizeKind::Grow, value: 1.0};
    root.height = CuiSize{kind: CuiSizeKind::Grow, value: 1.0};
    root.bg = toCuiColor(window.bg);
    cui_column_begin(ui, &root);
    emitWidgets(ui, window);
    cui_box_end(ui);

    frames = frames + 1;
    if (smoke && frames >= 3) {
      cui_app_quit(app);
    }
  }

  guiCtx = nullptr;
  guiApp = nullptr;
  return 0;
}
