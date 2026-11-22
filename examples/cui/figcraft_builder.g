// FigCraft UI Builder built with Glang std.gui and CUI.
//
// A 1:1 recreation of ArtCraft FigCraft's light UI3 workspace using the
// std.gui builder pattern: tab strip, left rail, pages/layers panel,
// interactive canvas, Design/Prototype inspector, and floating toolbar.
//
// Build with: examples\cui\build.cmd -Builder. Set CUI_SMOKE=1 for a hidden run.

import std.gui;
import std.pipe;
import std.cui;

// ---------------------------------------------------------------------------
// Palette
// ---------------------------------------------------------------------------

Color chromeColor() => gui::rgb(239, 239, 239);
Color panelColor() => gui::rgb(252, 252, 252);
Color cardColor() => gui::rgb(255, 255, 255);
Color canvasColor() => gui::rgb(238, 238, 238);
Color borderColor() => gui::rgb(226, 226, 226);
Color dividerColor() => gui::rgb(234, 234, 234);
Color textColor() => gui::rgb(28, 28, 30);
Color secondaryText() => gui::rgb(105, 105, 110);
Color mutedText() => gui::rgb(150, 150, 155);
Color fieldColor() => gui::rgb(245, 245, 246);
Color pageSelected() => gui::rgb(240, 240, 241);
Color greenColor() => gui::rgb(10, 207, 131);
Color greenDark() => gui::rgb(5, 134, 86);
Color greenSoft() => gui::rgb(219, 247, 234);
Color navyColor() => gui::rgb(15, 23, 38);
Color navyRaised() => gui::rgb(27, 39, 59);
Color designBg() => gui::rgb(243, 245, 248);
Color designBorder() => gui::rgb(231, 234, 239);
Color chartGreen() => gui::rgb(16, 163, 127);
Color chartMint() => gui::rgb(178, 235, 215);
Color chartBlue() => gui::rgb(59, 130, 246);
Color warningColor() => gui::rgb(217, 145, 38);
Color warningSoft() => gui::rgb(253, 243, 219);
Color dangerColor() => gui::rgb(226, 84, 84);
Color blueSoft() => gui::rgb(225, 236, 254);

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

enum NodeKind {
  NodeRectangle,
  NodeText,
  NodeChart,
  NodeButton,
  NodeDonut,
  NodeLine
}

struct DesignNode {
  int kind;
  int id;
  float x;
  float y;
  float w;
  float h;
  float radius;
  float border;
  float textSize;
  int font;
  Color fill;
  Color ink;
  Color stroke;
  bool visible;
  bool locked;
  char[64] name;
}

struct Editor {
  DesignNode[160] nodes;
  int count;
  int nextId;
  int selected;
  int tool;
  int leftTab;
  int rightTab;
  int bottomMode;
  int selectedPage;
  bool clipContent;
  bool fillVisible;
  bool dragging;
  float dragStartX;
  float dragStartY;
  float dragMouseX;
  float dragMouseY;
  bool panning;
  float offsetX;
  float offsetY;
  float stageScreenX;
  float stageScreenY;
}

Editor ed;

void copyName(char* dest, const char* src) {
  int i = 0;
  while (src[i] != '\0' && i < 63) {
    dest[i] = src[i];
    i = i + 1;
  }
  dest[i] = '\0';
}

void addShape(Editor* e, NodeKind kind, const char* name,
              float x, float y, float w, float h,
              Color fill, Color ink, Color stroke,
              float radius, float border, float textSize, int font) {
  if (e.count >= 160) {
    return;
  }
  DesignNode node = DesignNode{
    kind: kind as int,
    id: e.nextId,
    x: x,
    y: y,
    w: w,
    h: h,
    radius: radius,
    border: border,
    textSize: textSize,
    font: font,
    fill: fill,
    ink: ink,
    stroke: stroke,
    visible: true,
    locked: false
  };
  copyName(&node.name[0], name);
  e.nextId = e.nextId + 1;
  e.nodes[e.count] = node;
  e.count = e.count + 1;
}

void addRect(Editor* e, const char* name, float x, float y, float w, float h,
             Color fill, float radius, float border, Color stroke) {
  addShape(e, NodeKind::NodeRectangle, name, x, y, w, h, fill, gui::clear(), stroke, radius, border, 0.0, 0);
}

void addText(Editor* e, const char* name, float x, float y, float w, float h,
             float size, Color ink, int font) {
  addShape(e, NodeKind::NodeText, name, x, y, w, h, gui::clear(), ink, gui::clear(), 0.0, 0.0, size, font);
}

void addChart(Editor* e, const char* name, float x, float y, float w, float h, Color bar) {
  addShape(e, NodeKind::NodeChart, name, x, y, w, h, bar, gui::clear(), gui::clear(), 0.0, 0.0, 0.0, 0);
}

void addButton(Editor* e, const char* name, float x, float y, float w, float h,
               Color fill, Color ink) {
  addShape(e, NodeKind::NodeButton, name, x, y, w, h, fill, ink, gui::clear(), 7.0, 0.0, 12.0, 1);
}

void addDonut(Editor* e, const char* name, float x, float y, float w, float h) {
  addShape(e, NodeKind::NodeDonut, name, x, y, w, h, greenColor(), textColor(), gui::clear(), 0.0, 0.0, 0.0, 0);
}

void addLine(Editor* e, const char* name, float x, float y, float w, float h, Color color) {
  addShape(e, NodeKind::NodeLine, name, x, y, w, h, color, gui::clear(), gui::clear(), 0.0, 0.0, 0.0, 0);
}

void addCircleDot(Editor* e, const char* name, float x, float y, Color color) {
  addShape(e, NodeKind::NodeButton, name, x, y, 7.0, 7.0, color, gui::clear(), gui::clear(), 3.5, 0.0, 0.0, 0);
}

void initScene(Editor* e) {
  Color sidebar = gui::rgb(12, 25, 41);
  Color sidebarRaised = gui::rgb(23, 43, 62);
  Color navMuted = gui::rgb(164, 179, 196);
  Color ink = gui::rgb(23, 32, 44);
  Color muted = gui::rgb(122, 135, 148);
  Color line = gui::rgb(231, 235, 240);
  Color green = greenColor();
  Color blue = chartBlue();

  // Sidebar
  addRect(e, "Sidebar", 0, 0, 265, 960, sidebar, 0.0, 0.0, gui::clear());
  addRect(e, "Brand mark", 21, 21, 37, 37, green, 10.0, 0.0, gui::clear());
  addText(e, "R", 33, 26, 20, 26, 17, sidebar, 1);
  addText(e, "Ridgeline", 67, 21, 150, 26, 14, cardColor(), 1);
  addText(e, "STUDIO", 68, 43, 100, 16, 8, navMuted, 0);
  addRect(e, "Overview active", 21, 69, 223, 42, sidebarRaised, 8.0, 0.0, gui::clear());
  addText(e, "Overview", 55, 80, 150, 22, 13, cardColor(), 1);
  addText(e, "Analytics", 55, 131, 150, 22, 13, navMuted, 0);
  addText(e, "Trails", 55, 182, 150, 22, 13, navMuted, 0);
  addText(e, "Rangers", 55, 233, 150, 22, 13, navMuted, 0);
  addText(e, "Bookings", 55, 284, 150, 22, 13, navMuted, 0);
  addText(e, "Alerts", 55, 335, 150, 22, 13, navMuted, 0);
  addText(e, "Settings", 55, 386, 150, 22, 13, navMuted, 0);

  addRect(e, "Winter planner", 21, 716, 223, 150, gui::rgb(18, 73, 57), 10.0, 0.0, gui::clear());
  addText(e, "Winter season", 36, 731, 190, 24, 12, cardColor(), 1);
  addText(e, "Plan closures and snow", 36, 758, 192, 16, 9, gui::rgb(199, 235, 222), 0);
  addText(e, "routes before the first storm.", 36, 774, 192, 16, 8, gui::rgb(199, 235, 222), 0);
  addButton(e, "Open planner", 36, 812, 193, 30, green, sidebar);
  addCircleDot(e, "Avatar", 21, 904, green);
  addText(e, "JO", 30, 905, 20, 16, 7, sidebar, 1);
  addText(e, "Jonas Ortiz", 56, 897, 150, 20, 10, cardColor(), 0);
  addText(e, "Park operations", 56, 917, 150, 16, 8, navMuted, 0);

  // Header
  addText(e, "Good afternoon, Jonas", 289, 33, 560, 36, 21, ink, 1);
  addText(e, "Here is how the park's trails did this week.", 289, 66, 520, 20, 10, muted, 0);
  addRect(e, "Search field", 893, 40, 222, 44, cardColor(), 10.0, 1.0, line);
  addText(e, "Search trails or rangers", 914, 53, 190, 20, 9, gui::rgb(150, 160, 172), 0);
  addRect(e, "Date chip", 1129, 40, 136, 44, cardColor(), 9.0, 1.0, line);
  addText(e, "6 - 12 Oct 2026", 1147, 53, 118, 20, 8, muted, 0);
  addButton(e, "New trail", 1279, 40, 136, 44, green, sidebar);

  // KPI row
  addRect(e, "KPI hikers", 289, 123, 268, 152, cardColor(), 9.0, 1.0, line);
  addText(e, "Active hikers", 303, 137, 200, 18, 9.7, muted, 0);
  addText(e, "12,480", 303, 154, 220, 42, 26.5, ink, 1);
  addText(e, "^ 18.2% vs last week", 303, 239, 230, 18, 8.6, green, 0);

  addRect(e, "KPI check-ins", 575, 123, 268, 152, cardColor(), 9.0, 1.0, line);
  addText(e, "Trail check-ins", 589, 137, 200, 18, 9.7, muted, 0);
  addText(e, "3,916", 589, 154, 220, 42, 26.5, ink, 1);
  addText(e, "^ 12.4% vs last week", 589, 239, 230, 18, 8.6, green, 0);

  addRect(e, "KPI rating", 861, 123, 268, 152, cardColor(), 9.0, 1.0, line);
  addText(e, "Avg. rating", 875, 137, 200, 18, 9.7, muted, 0);
  addText(e, "4.82", 875, 154, 220, 42, 26.5, ink, 1);
  addText(e, "^ 0.06 vs last week", 875, 239, 230, 18, 8.6, green, 0);

  addRect(e, "KPI incidents", 1147, 123, 268, 152, cardColor(), 9.0, 1.0, line);
  addText(e, "Open incidents", 1161, 137, 200, 18, 9.7, muted, 0);
  addText(e, "7", 1161, 154, 220, 42, 26.5, ink, 1);
  addText(e, "v 3 vs last week", 1161, 239, 230, 18, 8.6, dangerColor(), 0);

  // Hikes bar card
  addRect(e, "Hikes card", 289, 293, 772, 328, cardColor(), 9.0, 1.0, line);
  addText(e, "Hikes per day", 305, 308, 260, 26, 13, ink, 1);
  addText(e, "2,184 this week - +9% on last week", 305, 329, 360, 18, 8.5, muted, 0);
  addChart(e, "Hikes bars", 305, 352, 740, 222, chartGreen());
  addText(e, "Mon", 336, 582, 40, 16, 8.5, muted, 0);
  addText(e, "Tue", 442, 582, 40, 16, 8.5, muted, 0);
  addText(e, "Wed", 548, 582, 40, 16, 8.5, muted, 0);
  addText(e, "Thu", 654, 582, 40, 16, 8.5, muted, 0);
  addText(e, "Fri", 760, 582, 40, 16, 8.5, muted, 0);
  addText(e, "Sat", 866, 582, 40, 16, 8.5, muted, 0);
  addText(e, "Sun", 972, 582, 40, 16, 8.5, muted, 0);

  // Difficulty donut card
  addRect(e, "Difficulty card", 1079, 293, 336, 328, cardColor(), 9.0, 1.0, line);
  addText(e, "Difficulty mix", 1095, 308, 240, 26, 13, ink, 1);
  addDonut(e, "Difficulty donut", 1095, 336, 304, 208);
  addCircleDot(e, "Easy dot", 1097, 565, chartGreen());
  addText(e, "Easy", 1110, 558, 60, 18, 8.6, muted, 0);
  addCircleDot(e, "Moderate dot", 1176, 565, blue);
  addText(e, "Moderate", 1189, 558, 90, 18, 8.6, muted, 0);
  addCircleDot(e, "Hard dot", 1292, 565, warningColor());
  addText(e, "Hard", 1305, 558, 60, 18, 8.6, muted, 0);

  // Trails card
  addRect(e, "Trails card", 289, 639, 772, 296, cardColor(), 9.0, 1.0, line);
  addText(e, "Top trails this week", 305, 654, 300, 26, 13, ink, 1);
  addText(e, "View all", 987, 657, 60, 18, 9, greenDark(), 0);
  addText(e, "TRAIL                         REGION               HIKES      RATING      CONDITIONS",
          305, 684, 740, 16, 7.6, muted, 0);
  addRect(e, "Open pill", 896, 706, 74, 28, greenSoft(), 14.0, 0.0, gui::clear());
  addText(e, "Larch Valley Loop", 305, 711, 240, 22, 10.2, ink, 0);
  addText(e, "Lake district", 560, 713, 130, 20, 9, muted, 0);
  addText(e, "612", 700, 713, 50, 20, 9, ink, 0);
  addText(e, "4.9", 770, 713, 50, 20, 9, ink, 0);
  addText(e, "Open", 916, 713, 50, 18, 8.6, greenDark(), 1);

  addRect(e, "Open pill 2", 896, 748, 74, 28, greenSoft(), 14.0, 0.0, gui::clear());
  addText(e, "Emerald Lake Circuit", 305, 753, 240, 22, 10.2, ink, 0);
  addText(e, "Yoho valley", 560, 755, 130, 20, 9, muted, 0);
  addText(e, "486", 700, 755, 50, 20, 9, ink, 0);
  addText(e, "4.8", 770, 755, 50, 20, 9, ink, 0);
  addText(e, "Open", 916, 755, 50, 18, 8.6, greenDark(), 1);

  addRect(e, "Muddy pill", 896, 790, 74, 28, warningSoft(), 14.0, 0.0, gui::clear());
  addText(e, "Sulphur Ridge Lookout", 305, 795, 240, 22, 10.2, ink, 0);
  addText(e, "Hot springs", 560, 797, 130, 20, 9, muted, 0);
  addText(e, "351", 700, 797, 50, 20, 9, ink, 0);
  addText(e, "4.7", 770, 797, 50, 20, 9, ink, 0);
  addText(e, "Muddy", 912, 797, 60, 18, 8.6, warningColor(), 1);

  addRect(e, "Snow pill", 896, 832, 74, 28, blueSoft(), 14.0, 0.0, gui::clear());
  addText(e, "Tunnel Peak Traverse", 305, 837, 240, 22, 10.2, ink, 0);
  addText(e, "North gate", 560, 839, 130, 20, 9, muted, 0);
  addText(e, "207", 700, 839, 50, 20, 9, ink, 0);
  addText(e, "4.6", 770, 839, 50, 20, 9, ink, 0);
  addText(e, "Snow", 914, 839, 60, 18, 8.6, chartBlue(), 1);

  // Visitors card
  addRect(e, "Visitors card", 1079, 639, 336, 296, cardColor(), 9.0, 1.0, line);
  addText(e, "Visitors, last 30 days", 1095, 654, 240, 22, 12, ink, 0);
  addText(e, "+18%", 1352, 657, 60, 18, 9, greenDark(), 0);
  addText(e, "41,230", 1095, 678, 220, 44, 28, ink, 1);
  addLine(e, "Visitors trend", 1095, 724, 304, 168, blue);
  addText(e, "12 Sep", 1095, 904, 60, 18, 7.4, muted, 0);
  addText(e, "22 Sep", 1180, 904, 60, 18, 7.4, muted, 0);
  addText(e, "2 Oct", 1262, 904, 60, 18, 7.4, muted, 0);
  addText(e, "12 Oct", 1340, 904, 60, 18, 7.4, muted, 0);
}

const char* nodeGlyph(int kind) {
  if (kind == NodeKind::NodeText as int) {
    return std::cui::icons::textTool();
  }
  if (kind == NodeKind::NodeChart as int) {
    return std::cui::icons::chartBar();
  }
  if (kind == NodeKind::NodeLine as int) {
    return std::cui::icons::activity();
  }
  if (kind == NodeKind::NodeDonut as int) {
    return std::cui::icons::chartLine();
  }
  if (kind == NodeKind::NodeButton as int) {
    return std::cui::icons::circle();
  }
  return std::cui::icons::square();
}

// ---------------------------------------------------------------------------
// Canvas drawing
// ---------------------------------------------------------------------------

void drawHandle(Draw* draw, float x, float y) {
  gui::rectBorder(draw, x - 3.5, y - 3.5, 7.0, 7.0, 1.0, cardColor(), greenDark(), 1.0);
}

void drawHandles(Draw* draw, float x, float y, float w, float h) {
  drawHandle(draw, x, y);
  drawHandle(draw, x + w, y);
  drawHandle(draw, x, y + h);
  drawHandle(draw, x + w, y + h);
  drawHandle(draw, x + w * 0.5, y);
  drawHandle(draw, x + w * 0.5, y + h);
  drawHandle(draw, x, y + h * 0.5);
  drawHandle(draw, x + w, y + h * 0.5);
}

void paintStage() {
  Draw* draw = gui::paintDraw();
  float scale = 816.0 / 1440.0;
  float fx = draw.rect.x;
  float fy = draw.rect.y;

  ed.stageScreenX = fx;
  ed.stageScreenY = fy;

  // Frame background
  if (ed.fillVisible) {
    gui::rect(draw, fx, fy, 816.0, 544.0, 2.0, designBg());
  }

  // Clip content if enabled
  if (ed.clipContent) {
    gui::pushClip(draw, fx, fy, 816.0, 544.0);
  }

  // Render all scene nodes
  for (int i = 0; i < ed.count; i = i + 1) {
    if (!ed.nodes[i].visible) {
      continue;
    }
    float nx = fx + ed.nodes[i].x * scale;
    float ny = fy + ed.nodes[i].y * scale;
    float nw = ed.nodes[i].w * scale;
    float nh = ed.nodes[i].h * scale;
    float nr = ed.nodes[i].radius * scale;

    if (ed.nodes[i].kind == (NodeKind::NodeRectangle as int)) {
      if (ed.nodes[i].border > 0.0) {
        gui::rectBorder(draw, nx, ny, nw, nh, nr, ed.nodes[i].fill, ed.nodes[i].stroke, ed.nodes[i].border);
      } else {
        gui::rect(draw, nx, ny, nw, nh, nr, ed.nodes[i].fill);
      }
    } else if (ed.nodes[i].kind == (NodeKind::NodeButton as int)) {
      gui::rect(draw, nx, ny, nw, nh, nr, ed.nodes[i].fill);
    } else if (ed.nodes[i].kind == (NodeKind::NodeText as int)) {
      GuiFont f = if (ed.nodes[i].font == 1) gui::medium() else gui::body();
      gui::text(draw, &ed.nodes[i].name[0], nx, ny, ed.nodes[i].textSize * scale, f, ed.nodes[i].ink);
    } else if (ed.nodes[i].kind == (NodeKind::NodeChart as int)) {
      float barW = 8.0;
      float[7] heights;
      heights[0] = 42.0; heights[1] = 58.0; heights[2] = 36.0;
      heights[3] = 66.0; heights[4] = 52.0; heights[5] = 78.0; heights[6] = 68.0;
      for (int b = 0; b < 7; b = b + 1) {
        float bx = nx + (b as float) * (nw / 7.0) + 12.0;
        float bh = heights[b] * scale;
        gui::rect(draw, bx, ny + nh - bh, barW, bh, 2.0, ed.nodes[i].fill);
      }
    } else if (ed.nodes[i].kind == (NodeKind::NodeDonut as int)) {
      gui::circle(draw, nx + nw * 0.5, ny + nh * 0.5, nw * 0.28, ed.nodes[i].fill);
      gui::circle(draw, nx + nw * 0.5, ny + nh * 0.5, nw * 0.16, designBg());
    } else if (ed.nodes[i].kind == (NodeKind::NodeLine as int)) {
      gui::line(draw, nx, ny + nh * 0.8, nx + nw * 0.3, ny + nh * 0.4, 2.0, ed.nodes[i].fill);
      gui::line(draw, nx + nw * 0.3, ny + nh * 0.4, nx + nw * 0.6, ny + nh * 0.5, 2.0, ed.nodes[i].fill);
      gui::line(draw, nx + nw * 0.6, ny + nh * 0.5, nx + nw, ny + nh * 0.2, 2.0, ed.nodes[i].fill);
    }
  }

  if (ed.clipContent) {
    gui::popClip(draw);
  }

  // Selection outline & handles
  if (ed.selected < 0) {
    gui::rectBorder(draw, fx, fy, 816.0, 544.0, 2.0, gui::clear(), greenColor(), 1.5);
    drawHandles(draw, fx, fy, 816.0, 544.0);
  } else if (ed.selected < ed.count) {
    float sx = fx + ed.nodes[ed.selected].x * scale;
    float sy = fy + ed.nodes[ed.selected].y * scale;
    float sw = ed.nodes[ed.selected].w * scale;
    float sh = ed.nodes[ed.selected].h * scale;
    gui::rectBorder(draw, sx, sy, sw, sh, 0.0, gui::clear(), greenColor(), 1.5);
    drawHandles(draw, sx, sy, sw, sh);
  }
}

// ---------------------------------------------------------------------------
// Canvas interaction & input
// ---------------------------------------------------------------------------

void handleCanvasInput() {
  if (gui::keyPressed(GuiKey::GuiKeyV)) { ed.tool = 0; }
  if (gui::keyPressed(GuiKey::GuiKeyF)) { ed.tool = 1; }
  if (gui::keyPressed(GuiKey::GuiKeyR)) { ed.tool = 2; }
  if (gui::keyPressed(GuiKey::GuiKeyT)) { ed.tool = 4; }
  if (gui::keyPressed(GuiKey::GuiKeyDelete) || gui::keyPressed(GuiKey::GuiKeyBackspace)) {
    if (ed.selected >= 0 && ed.selected < ed.count) {
      for (int j = ed.selected; j < ed.count - 1; j = j + 1) {
        ed.nodes[j] = ed.nodes[j + 1];
      }
      ed.count = ed.count - 1;
      ed.selected = -1;
    }
  }

  float scale = 816.0 / 1440.0;
  float mx = gui::mouseX();
  float my = gui::mouseY();
  float sx = ed.stageScreenX;
  float sy = ed.stageScreenY;

  if (gui::mouseClicked()) {
    if (mx >= sx && mx < sx + 816.0 && my >= sy && my < sy + 544.0) {
      float dx = (mx - sx) / scale;
      float dy = (my - sy) / scale;

      if (ed.tool == 0) {
        int hit = -1;
        for (int i = ed.count - 1; i >= 0; i = i - 1) {
          if (!ed.nodes[i].visible) {
            continue;
          }
          if (dx >= ed.nodes[i].x && dx <= ed.nodes[i].x + ed.nodes[i].w &&
              dy >= ed.nodes[i].y && dy <= ed.nodes[i].y + ed.nodes[i].h) {
            hit = i;
            break;
          }
        }
        if (hit >= 0) {
          ed.selected = hit;
          ed.dragging = true;
          ed.dragStartX = ed.nodes[hit].x;
          ed.dragStartY = ed.nodes[hit].y;
          ed.dragMouseX = mx;
          ed.dragMouseY = my;
        } else {
          ed.selected = -1;
          ed.dragging = true;
          ed.dragStartX = ed.offsetX;
          ed.dragStartY = ed.offsetY;
          ed.dragMouseX = mx;
          ed.dragMouseY = my;
        }
      } else if (ed.tool == 2) {
        addRect(&ed, "Rectangle", dx, dy, 120.0, 80.0, greenColor(), 8.0, 1.0, gui::clear());
        ed.selected = ed.count - 1;
        ed.tool = 0;
      } else if (ed.tool == 4) {
        addText(&ed, "Text", dx, dy, 140.0, 30.0, 14.0, textColor(), 0);
        ed.selected = ed.count - 1;
        ed.tool = 0;
      }
    } else if (mx >= 300.0 && mx < gui::windowWidth() as float - 300.0 && my >= 50.0 && my < gui::windowHeight() as float - 64.0) {
      ed.panning = true;
      ed.dragStartX = ed.offsetX;
      ed.dragStartY = ed.offsetY;
      ed.dragMouseX = mx;
      ed.dragMouseY = my;
    }
  }

  if (ed.dragging) {
    if (gui::mouseDown()) {
      if (ed.selected >= 0 && ed.selected < ed.count) {
        ed.nodes[ed.selected].x = ed.dragStartX + (mx - ed.dragMouseX) / scale;
        ed.nodes[ed.selected].y = ed.dragStartY + (my - ed.dragMouseY) / scale;
      } else {
        ed.offsetX = ed.dragStartX + (mx - ed.dragMouseX);
        ed.offsetY = ed.dragStartY + (my - ed.dragMouseY);
      }
    } else {
      ed.dragging = false;
    }
  }

  if (ed.panning) {
    if (gui::mouseDown()) {
      ed.offsetX = ed.dragStartX + (mx - ed.dragMouseX);
      ed.offsetY = ed.dragStartY + (my - ed.dragMouseY);
    } else {
      ed.panning = false;
    }
  }
}

// ---------------------------------------------------------------------------
// UI Builders
// ---------------------------------------------------------------------------

Widget* buildTopBar() {
  auto bar = Row::new()
    |> set_size(fill(), 50px)
    |> set_bg(chromeColor())
    |> set_align(GuiAlign::GuiAlignCenter);

  auto homeBtn = Box::new()
    |> set_size(52px, fill())
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> gui::toast("Home", "The FigCraft home screen is part of the full app."); return; };
  homeBtn.add(Icon::new() |> set_icon(std::cui::icons::home()) |> set_text_size(17.0) |> set_text_color(textColor()));
  bar.add(homeBtn);

  auto tab = Row::new()
    |> set_size(252px, fill())
    |> set_padding_xy(12.0, 0.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(cardColor())
    |> set_border(1.0, dividerColor())
    |> set_corners(7.0, 7.0, 0.0, 0.0);
  tab.add(Icon::new() |> set_icon(std::cui::icons::layers()) |> set_text_size(14.0) |> set_text_color(greenDark()));
  tab.add(Text::new() |> set_text("Ridgeline Studio dashboard") |> set_text_size(12.0) |> set_text_color(textColor()));
  tab.add(Spacer::new() |> set_size(fill(), 1px));
  auto closeTab = Box::new()
    |> set_size(20px, 20px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> gui::toast("Tab", "This mock keeps its one open file."); return; };
  closeTab.add(Icon::new() |> set_icon(std::cui::icons::x()) |> set_text_size(13.0) |> set_text_color(mutedText()));
  tab.add(closeTab);
  bar.add(tab);

  auto newTab = Box::new()
    |> set_size(32px, fill())
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> gui::toast("New file", "New files open in another tab in the full app."); return; };
  newTab.add(Icon::new() |> set_icon(std::cui::icons::plus()) |> set_text_size(15.0) |> set_text_color(secondaryText()));
  bar.add(newTab);

  bar.add(Spacer::new() |> set_size(fill(), 1px));

  auto winTools = Row::new()
    |> set_size(fit(), fill())
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(4.0)
    |> set_align(GuiAlign::GuiAlignCenter);

  auto minBtn = Box::new() |> set_size(28px, 28px) |> set_align(GuiAlign::GuiAlignCenter) |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> gui::minimize(); return; };
  minBtn.add(Icon::new() |> set_icon(std::cui::icons::minus()) |> set_text_size(15.0) |> set_text_color(secondaryText()));
  winTools.add(minBtn);

  auto maxBtn = Box::new() |> set_size(28px, 28px) |> set_align(GuiAlign::GuiAlignCenter) |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> gui::toggleMaximize(); return; };
  maxBtn.add(Icon::new() |> set_icon(std::cui::icons::maximize()) |> set_text_size(14.0) |> set_text_color(secondaryText()));
  winTools.add(maxBtn);

  auto closeBtn = Box::new() |> set_size(28px, 28px) |> set_align(GuiAlign::GuiAlignCenter) |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> gui::quit(); return; };
  closeBtn.add(Icon::new() |> set_icon(std::cui::icons::x()) |> set_text_size(15.0) |> set_text_color(secondaryText()));
  winTools.add(closeBtn);

  bar.add(winTools);
  return bar;
}

Widget* railItem(const char* label, const char* glyph, int tabIndex) {
  bool selected = ed.leftTab == tabIndex;
  auto item = Column::new()
    |> set_size(fill(), 50px)
    |> set_gap(3.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> ed.leftTab = tabIndex; return; };
  Color iconCol = if (selected) greenDark() else secondaryText();
  Color textCol = if (selected) textColor() else secondaryText();
  item.add(Icon::new() |> set_icon(glyph) |> set_text_size(16.0) |> set_text_color(iconCol));
  item.add(Text::new() |> set_text(label) |> set_text_size(10.0) |> set_text_color(textCol));
  return item;
}

Widget* buildRail() {
  auto rail = Column::new()
    |> set_size(52px, fill())
    |> set_padding_each(9.0, 0.0, 8.0, 0.0)
    |> set_gap(4.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(panelColor())
    |> set_border(1.0, dividerColor());

  rail.add(railItem("Layers", std::cui::icons::layers(), 0));
  rail.add(railItem("Assets", std::cui::icons::box(), 1));
  rail.add(railItem("Vars", std::cui::icons::sliders(), 2));
  rail.add(Spacer::new() |> set_size(fill(), fill()));
  return rail;
}

Widget* buildLeftPanel() {
  auto panel = Column::new()
    |> set_size(248px, fill())
    |> set_bg(panelColor())
    |> set_border(1.0, dividerColor());

  if (ed.leftTab == 0) {
    auto header = Row::new()
      |> set_size(fill(), 53px)
      |> set_padding_xy(16.0, 0.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_gap(4.0);
    auto titleCol = Column::new() |> set_size(fill(), fit()) |> set_gap(1.0);
    titleCol.add(Text::new() |> set_text("Ridgeline Studio dashboard") |> set_text_size(12.0) |> set_text_color(textColor()) |> set_font(gui::medium()));
    titleCol.add(Text::new() |> set_text("Drafts") |> set_text_size(10.0) |> set_text_color(mutedText()));
    header.add(titleCol);
    panel.add(header);

    auto div1 = Divider::new() |> set_size(fill(), 1px) |> set_bg(dividerColor());
    panel.add(div1);

    auto pageRow = Row::new()
      |> set_size(fill(), 30px)
      |> set_padding_xy(16.0, 0.0)
      |> set_align(GuiAlign::GuiAlignCenter);
    pageRow.add(Text::new() |> set_text("Pages") |> set_text_size(10.5) |> set_text_color(textColor()) |> set_font(gui::medium()));
    panel.add(pageRow);

    auto pageItem = Row::new()
      |> set_size(fill(), 28px)
      |> set_padding_xy(16.0, 0.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_bg(pageSelected())
      |> set_radius(6.0);
    pageItem.add(Text::new() |> set_text("Dashboard") |> set_text_size(11.0) |> set_text_color(textColor()));
    panel.add(pageItem);

    auto div2 = Divider::new() |> set_size(fill(), 1px) |> set_bg(dividerColor());
    panel.add(div2);

    auto layersHeader = Row::new()
      |> set_size(fill(), 30px)
      |> set_padding_xy(16.0, 0.0)
      |> set_align(GuiAlign::GuiAlignCenter);
    layersHeader.add(Text::new() |> set_text("Layers") |> set_text_size(10.5) |> set_text_color(textColor()) |> set_font(gui::medium()));
    panel.add(layersHeader);

    auto scroll = Scroll::new()
      |> set_size(fill(), fill())
      |> set_padding_xy(8.0, 2.0)
      |> set_gap(2.0);

    // Root frame row
    bool rootSelected = ed.selected < 0;
    auto rootRow = Row::new()
      |> set_size(fill(), 30px)
      |> set_padding_xy(8.0, 0.0)
      |> set_gap(6.0)
      |> set_align(GuiAlign::GuiAlignCenter)
      |> set_bg(if (rootSelected) greenSoft() else panelColor())
      |> set_radius(6.0)
      |> on_click() { -> ed.selected = -1; return; };
    rootRow.add(Icon::new() |> set_icon(std::cui::icons::layers()) |> set_text_size(13.0) |> set_text_color(if (rootSelected) greenDark() else secondaryText()));
    rootRow.add(Text::new() |> set_text("Dashboard - Overview") |> set_text_size(11.0) |> set_text_color(textColor()));
    scroll.add(rootRow);

    // Node rows
    for (int i = ed.count - 1; i >= 0; i = i - 1) {
      if (!ed.nodes[i].visible) {
        continue;
      }
      int idx = i;
      bool isSel = ed.selected == idx;
      auto nodeRow = Row::new()
        |> set_size(fill(), 28px)
        |> set_padding_xy(18.0, 0.0)
        |> set_gap(6.0)
        |> set_align(GuiAlign::GuiAlignCenter)
        |> set_bg(if (isSel) greenSoft() else panelColor())
        |> set_radius(6.0)
        |> on_click() { -> ed.selected = idx; return; };
      nodeRow.add(Icon::new() |> set_icon(nodeGlyph(ed.nodes[i].kind)) |> set_text_size(12.0) |> set_text_color(if (isSel) greenDark() else secondaryText()));
      nodeRow.add(Text::new() |> set_text(&ed.nodes[i].name[0]) |> set_text_size(11.0) |> set_text_color(textColor()));
      scroll.add(nodeRow);
    }
    panel.add(scroll);
  } else {
    auto title = Box::new() |> set_size(fill(), 40px) |> set_padding_xy(16.0, 10.0);
    title.add(Text::new() |> set_text(if (ed.leftTab == 1) "Assets" else "Variables") |> set_text_size(12.0) |> set_font(gui::medium()));
    panel.add(title);
    panel.add(Spacer::new() |> set_size(fill(), fill()));
  }

  return panel;
}

Widget* toolBtn(const char* glyph, int toolIdx, const char* tip) {
  bool active = ed.tool == toolIdx;
  auto btn = Box::new()
    |> set_size(28px, 28px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_bg(if (active) greenColor() else gui::clear())
    |> set_radius(6.0)
    |> set_tooltip(tip)
    |> on_click() { -> ed.tool = toolIdx; return; };
  btn.add(Icon::new() |> set_icon(glyph) |> set_text_size(14.0) |> set_text_color(if (active) navyColor() else secondaryText()));
  return btn;
}

Widget* buildBottomToolbar() {
  auto toolbar = Row::new()
    |> set_size(fit(), 44px)
    |> set_padding_xy(8.0, 0.0)
    |> set_gap(2.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_bg(cardColor())
    |> set_border(1.0, dividerColor())
    |> set_radius(12.0)
    |> set_elevation(GuiElevation::GuiElevationFloating);

  toolbar.add(toolBtn(std::cui::icons::move(), 0, "Move (V)"));
  toolbar.add(toolBtn(std::cui::icons::grid(), 1, "Frame (F)"));
  toolbar.add(toolBtn(std::cui::icons::square(), 2, "Rectangle (R)"));
  toolbar.add(toolBtn(std::cui::icons::pencil(), 3, "Pen (P)"));
  toolbar.add(toolBtn(std::cui::icons::textTool(), 4, "Text (T)"));
  toolbar.add(toolBtn(std::cui::icons::message(), 5, "Comment (C)"));

  toolbar.add(Divider::new() |> set_size(1px, 20px) |> set_bg(dividerColor()));

  auto modePill = Row::new()
    |> set_size(fit(), 28px)
    |> set_padding_xy(4.0, 0.0)
    |> set_gap(2.0)
    |> set_bg(fieldColor())
    |> set_radius(7.0)
    |> set_align(GuiAlign::GuiAlignCenter);
  modePill.add(toolBtn(std::cui::icons::pencil(), 0, "Draw"));
  modePill.add(toolBtn(std::cui::icons::grid(), 1, "Layout"));
  modePill.add(toolBtn(std::cui::icons::code(), 2, "Dev mode"));
  toolbar.add(modePill);

  return toolbar;
}

Widget* buildCanvas() {
  auto canvasArea = Column::new()
    |> set_size(fill(), fill())
    |> set_bg(canvasColor())
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> set_gap(10.0);

  auto stageBox = Column::new()
    |> set_size(816px, 570px)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_gap(4.0);

  auto canvas = Canvas::new()
    |> set_size(816px, 544px)
    |> on_paint() { -> paintStage(); return; };
  stageBox.add(canvas);

  // Badge under frame
  auto badge = Box::new()
    |> set_size(fit(), 20px)
    |> set_padding_xy(8.0, 0.0)
    |> set_bg(greenColor())
    |> set_radius(4.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  const char* bText = if (ed.selected < 0) "1440 x 960" else &ed.nodes[ed.selected].name[0];
  badge.add(Text::new() |> set_text(bText) |> set_text_size(8.5) |> set_text_color(cardColor()) |> set_font(gui::medium()));
  stageBox.add(badge);

  canvasArea.add(stageBox);
  canvasArea.add(buildBottomToolbar());
  return canvasArea;
}

Widget* buildDesignInspector() {
  auto body = Column::new()
    |> set_size(fill(), fill())
    |> set_padding(14.0)
    |> set_gap(10.0);

  // Type header
  auto typeRow = Row::new() |> set_size(fill(), 26px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(6.0);
  const char* selName = if (ed.selected < 0) "Frame" else &ed.nodes[ed.selected].name[0];
  typeRow.add(Text::new() |> set_text(selName) |> set_text_size(12.0) |> set_text_color(textColor()) |> set_font(gui::medium()));
  typeRow.add(Icon::new() |> set_icon(std::cui::icons::chevronDown()) |> set_text_size(11.0) |> set_text_color(secondaryText()));
  typeRow.add(Spacer::new() |> set_size(fill(), 1px));
  typeRow.add(Icon::new() |> set_icon(std::cui::icons::rotateCcw()) |> set_text_size(13.0) |> set_text_color(secondaryText()));
  typeRow.add(Icon::new() |> set_icon(std::cui::icons::link()) |> set_text_size(13.0) |> set_text_color(secondaryText()));
  body.add(typeRow);

  body.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(dividerColor()));

  // Position label & scrubs
  body.add(Text::new() |> set_text("Position") |> set_text_size(10.0) |> set_text_color(secondaryText()));
  auto posRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
  if (ed.selected >= 0 && ed.selected < ed.count) {
    posRow.add(Scrub::new() |> set_text("X") |> set_value(&ed.nodes[ed.selected].x, -5000.0, 5000.0) |> set_width(122px));
    posRow.add(Scrub::new() |> set_text("Y") |> set_value(&ed.nodes[ed.selected].y, -5000.0, 5000.0) |> set_width(122px));
  } else {
    posRow.add(Scrub::new() |> set_text("X") |> set_value(&ed.offsetX, -5000.0, 5000.0) |> set_width(122px));
    posRow.add(Scrub::new() |> set_text("Y") |> set_value(&ed.offsetY, -5000.0, 5000.0) |> set_width(122px));
  }
  body.add(posRow);

  // Dimensions label & scrubs
  body.add(Text::new() |> set_text("Dimensions") |> set_text_size(10.0) |> set_text_color(secondaryText()));
  auto dimRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
  if (ed.selected >= 0 && ed.selected < ed.count) {
    dimRow.add(Scrub::new() |> set_text("W") |> set_value(&ed.nodes[ed.selected].w, 1.0, 5000.0) |> set_width(122px));
    dimRow.add(Scrub::new() |> set_text("H") |> set_value(&ed.nodes[ed.selected].h, 1.0, 5000.0) |> set_width(122px));
  } else {
    dimRow.add(Text::new() |> set_text("W: 1440") |> set_text_size(10.5));
    dimRow.add(Text::new() |> set_text("H: 960") |> set_text_size(10.5));
  }
  body.add(dimRow);

  // Corner radius
  if (ed.selected >= 0 && ed.selected < ed.count) {
    auto radRow = Row::new() |> set_size(fill(), fit()) |> set_gap(8.0);
    radRow.add(Scrub::new() |> set_text("R") |> set_value(&ed.nodes[ed.selected].radius, 0.0, 500.0) |> set_width(122px));
    body.add(radRow);
  }

  body.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(dividerColor()));

  // Clip content checkbox
  body.add(Checkbox::new() |> set_text("Clip content") |> set_checked(&ed.clipContent));

  body.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(dividerColor()));

  // Fill section
  auto fillHead = Row::new() |> set_size(fill(), 26px) |> set_align(GuiAlign::GuiAlignCenter);
  fillHead.add(Text::new() |> set_text("Fill") |> set_text_size(10.5) |> set_font(gui::medium()));
  fillHead.add(Spacer::new() |> set_size(fill(), 1px));
  auto eyeBtn = Box::new() |> set_size(24px, 24px) |> set_align(GuiAlign::GuiAlignCenter) |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> ed.fillVisible = !ed.fillVisible; return; };
  const char* eyeIcon = if (ed.fillVisible) std::cui::icons::eye() else std::cui::icons::eyeOff();
  eyeBtn.add(Icon::new() |> set_icon(eyeIcon) |> set_text_size(12.0) |> set_text_color(mutedText()));
  fillHead.add(eyeBtn);
  body.add(fillHead);

  auto fillRow = Row::new() |> set_size(fill(), 26px) |> set_align(GuiAlign::GuiAlignCenter) |> set_gap(6.0);
  fillRow.add(Box::new() |> set_size(14px, 14px) |> set_bg(designBg()) |> set_border(1.0, borderColor()) |> set_radius(3.0));
  fillRow.add(Text::new() |> set_text("Surface/Canvas") |> set_text_size(10.0) |> set_text_color(secondaryText()));
  body.add(fillRow);

  body.add(Spacer::new() |> set_size(fill(), fill()));
  return body;
}

Widget* buildRightPanel() {
  auto panel = Column::new()
    |> set_size(300px, fill())
    |> set_bg(cardColor())
    |> set_border(1.0, dividerColor());

  // Top header with user avatar & share
  auto head = Row::new()
    |> set_size(fill(), 52px)
    |> set_padding_xy(16.0, 0.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter);

  auto avatar = Box::new()
    |> set_size(26px, 26px)
    |> set_bg(navyColor())
    |> set_radius(13.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter);
  avatar.add(Text::new() |> set_text("MC") |> set_text_size(7.5) |> set_text_color(cardColor()) |> set_font(gui::medium()));
  head.add(avatar);
  head.add(Icon::new() |> set_icon(std::cui::icons::chevronDown()) |> set_text_size(11.0) |> set_text_color(secondaryText()));
  head.add(Spacer::new() |> set_size(fill(), 1px));

  auto shareBtn = Box::new()
    |> set_size(76px, 32px)
    |> set_bg(greenColor())
    |> set_radius(8.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> gui::toast("Share link copied", "Anyone with the link can view this file."); return; };
  shareBtn.add(Text::new() |> set_text("Share") |> set_text_size(11.0) |> set_text_color(navyColor()) |> set_font(gui::medium()));
  head.add(shareBtn);
  panel.add(head);

  // Design / Prototype tabs
  auto tabs = Row::new()
    |> set_size(fill(), 40px)
    |> set_padding_xy(16.0, 0.0)
    |> set_gap(8.0)
    |> set_align(GuiAlign::GuiAlignCenter);

  bool designActive = ed.rightTab == 0;
  auto dTab = Box::new()
    |> set_size(68px, 26px)
    |> set_bg(if (designActive) cardColor() else gui::clear())
    |> set_border(if (designActive) 1.0 else 0.0, borderColor())
    |> set_radius(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> ed.rightTab = 0; return; };
  dTab.add(Text::new() |> set_text("Design") |> set_text_size(10.5) |> set_text_color(if (designActive) textColor() else mutedText()));
  tabs.add(dTab);

  auto pTab = Box::new()
    |> set_size(78px, 26px)
    |> set_bg(if (!designActive) cardColor() else gui::clear())
    |> set_border(if (!designActive) 1.0 else 0.0, borderColor())
    |> set_radius(6.0)
    |> set_align(GuiAlign::GuiAlignCenter)
    |> set_justify(GuiJustify::GuiJustifyCenter)
    |> on_click() { -> ed.rightTab = 1; return; };
  pTab.add(Text::new() |> set_text("Prototype") |> set_text_size(10.5) |> set_text_color(if (!designActive) textColor() else mutedText()));
  tabs.add(pTab);

  tabs.add(Spacer::new() |> set_size(fill(), 1px));
  tabs.add(Text::new() |> set_text("57%") |> set_text_size(10.0) |> set_text_color(secondaryText()));
  panel.add(tabs);

  panel.add(Divider::new() |> set_size(fill(), 1px) |> set_bg(dividerColor()));

  if (ed.rightTab == 0) {
    panel.add(buildDesignInspector());
  } else {
    auto pBody = Column::new() |> set_size(fill(), fill()) |> set_padding(16.0) |> set_gap(10.0);
    pBody.add(Text::new() |> set_text("Interactions") |> set_text_size(11.0) |> set_font(gui::medium()));
    pBody.add(Text::new() |> set_text("Present from the current frame to preview the flow.") |> set_text_size(9.5) |> set_text_color(mutedText()));
    panel.add(pBody);
  }

  return panel;
}

// ---------------------------------------------------------------------------
// Main UI Builder Callback
// ---------------------------------------------------------------------------

void buildUi(Widget* window) {
  handleCanvasInput();
  window.clear();

  auto root = Column::new()
    |> set_size(fill(), fill())
    |> set_gap(0.0)
    |> set_bg(chromeColor());

  root.add(buildTopBar());

  auto workspace = Row::new()
    |> set_size(fill(), fill())
    |> set_gap(0.0);

  workspace.add(buildRail());
  workspace.add(buildLeftPanel());
  workspace.add(buildCanvas());
  workspace.add(buildRightPanel());

  root.add(workspace);
  window.add(root);
}

int main() {
  ed = Editor{
    count: 0,
    nextId: 100,
    selected: -1,
    tool: 0,
    leftTab: 0,
    rightTab: 0,
    bottomMode: 0,
    selectedPage: 0,
    clipContent: true,
    fillVisible: true,
    dragging: false,
    dragStartX: 0.0,
    dragStartY: 0.0,
    dragMouseX: 0.0,
    dragMouseY: 0.0,
    panning: false,
    offsetX: 0.0,
    offsetY: 0.0,
    stageScreenX: 300.0,
    stageScreenY: 70.0
  };
  initScene(&ed);

  auto window = Window::new()
    |> set_size(1440px, 900px)
    |> set_title("FigCraft - Ridgeline Studio")
    |> set_bg(chromeColor());

  window.on_build() {
    -> buildUi(window);
    return;
  };

  return gui::run(window);
}
