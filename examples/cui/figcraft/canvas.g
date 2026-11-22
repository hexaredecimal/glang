// FigCraft Canvas Painting & Interactive Manipulation Engine.
// Renders dot grid, pan/zoom-transformed artboard, all DesignNode primitives,
// 12-column layout grid, wireframe mode, 8-handle resize/move, rubber-band tool creation,
// and keyboard shortcuts guarded by !gui::wantsKeyboard().

import std.gui;
import std.cui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;
import examples.cui.figcraft.geometry;
import examples.cui.figcraft.scene;
import examples.cui.figcraft.actions;

void drawSelectionHandle(Draw* draw, float x, float y, bool dark) {
  gui::rectBorder(draw, (x - 3.5) as float, (y - 3.5) as float, 7.0, 7.0,
                  1.0, fcCard(dark), fcGreenDark(), 1.0);
}

void drawAllHandles(Draw* draw, float x, float y, float w, float h, float inset, bool dark) {
  float l = x + inset;
  float r = x + w - inset;
  float t = y + inset;
  float b = y + h - inset;
  float cx = x + w * 0.5;
  float cy = y + h * 0.5;
  drawSelectionHandle(draw, l, t, dark);
  drawSelectionHandle(draw, r, t, dark);
  drawSelectionHandle(draw, l, b, dark);
  drawSelectionHandle(draw, r, b, dark);
  drawSelectionHandle(draw, cx, t, dark);
  drawSelectionHandle(draw, cx, b, dark);
  drawSelectionHandle(draw, l, cy, dark);
  drawSelectionHandle(draw, r, cy, dark);
}

void drawGroupedBars(Draw* draw, float nx, float ny, float nw, float nh, float scale, Color mainCol) {
  float[7] cur;
  cur[0] = 42.0; cur[1] = 58.0; cur[2] = 36.0;
  cur[3] = 66.0; cur[4] = 52.0; cur[5] = 78.0; cur[6] = 68.0;
  float[7] prev;
  prev[0] = 30.0; prev[1] = 36.0; prev[2] = 28.0;
  prev[3] = 44.0; prev[4] = 40.0; prev[5] = 60.0; prev[6] = 50.0;

  float slotW = nw / 7.0;
  float barW = gui::maxf(4.0, 14.0 * scale);
  float gap = gui::maxf(2.0, 5.0 * scale);
  float maxH = 82.0;

  for (int b = 0; b < 7; b = b + 1) {
    float cx = nx + (b as float) * slotW + slotW * 0.5;
    float ph = (prev[b] / maxH) * (nh * 0.90);
    float ch = (cur[b] / maxH) * (nh * 0.90);
    float px0 = cx - barW - gap * 0.5;
    float cx0 = cx + gap * 0.5;
    gui::rect(draw, px0, ny + nh - ph, barW, ph, 2.0, fcChartMint());
    gui::rect(draw, cx0, ny + nh - ch, barW, ch, 2.0, mainCol);
  }
}

void drawTrendPolyline(Draw* draw, float nx, float ny, float nw, float nh, Color col, int variant) {
  float[12] pts;
  if (variant == 1) {
    pts[0] = 0.25; pts[1] = 0.20; pts[2] = 0.38; pts[3] = 0.30;
    pts[4] = 0.50; pts[5] = 0.45; pts[6] = 0.62; pts[7] = 0.56;
    pts[8] = 0.72; pts[9] = 0.68; pts[10] = 0.85; pts[11] = 0.92;
  } else if (variant == 2) {
    pts[0] = 0.40; pts[1] = 0.45; pts[2] = 0.42; pts[3] = 0.55;
    pts[4] = 0.52; pts[5] = 0.62; pts[6] = 0.60; pts[7] = 0.72;
    pts[8] = 0.70; pts[9] = 0.80; pts[10] = 0.78; pts[11] = 0.88;
  } else if (variant == 3) {
    pts[0] = 0.85; pts[1] = 0.72; pts[2] = 0.78; pts[3] = 0.60;
    pts[4] = 0.66; pts[5] = 0.48; pts[6] = 0.54; pts[7] = 0.38;
    pts[8] = 0.34; pts[9] = 0.40; pts[10] = 0.28; pts[11] = 0.20;
  } else {
    pts[0] = 0.18; pts[1] = 0.26; pts[2] = 0.22; pts[3] = 0.35;
    pts[4] = 0.31; pts[5] = 0.46; pts[6] = 0.42; pts[7] = 0.58;
    pts[8] = 0.54; pts[9] = 0.72; pts[10] = 0.68; pts[11] = 0.90;
  }

  float step = nw / 11.0;
  for (int i = 0; i < 11; i = i + 1) {
    float x0 = nx + (i as float) * step;
    float y0 = ny + nh - pts[i] * nh;
    float x1 = nx + ((i + 1) as float) * step;
    float y1 = ny + nh - pts[i + 1] * nh;
    gui::line(draw, x0, y0, x1, y1, 2.0, col);
  }
}

void drawSegmentedDonut(Draw* draw, float nx, float ny, float nw, float nh) {
  float cx = nx + nw * 0.5;
  float cy = ny + nh * 0.5;
  float rad = gui::minf(nw, nh) * 0.34;
  float thick = gui::maxf(8.0, rad * 0.36);

  // Full background track + 3 color segments (45% Easy, 35% Moderate, 20% Hard)
  float pi2 = 6.283185;
  float a0 = -1.570796;
  float a1 = a0 + pi2 * 0.44;
  float a2 = a1 + pi2 * 0.34;
  float a3 = a0 + pi2 * 0.98;

  gui::arc(draw, cx, cy, rad, a0, a1, thick, fcChartGreen());
  gui::arc(draw, cx, cy, rad, a1 + 0.06, a2, thick, fcChartBlue());
  gui::arc(draw, cx, cy, rad, a2 + 0.06, a3, thick, fcWarning());
}

void drawVectorDiamond(Draw* draw, float nx, float ny, float nw, float nh, Color fill, Color stroke) {
  float cx = nx + nw * 0.5;
  float cy = ny + nh * 0.5;
  Color col = if (fill.a > 0) fill else fcGreen();
  Color lineCol = if (stroke.a > 0) stroke else fcGreenDark();
  gui::line(draw, cx, ny, nx + nw, cy, 2.0, col);
  gui::line(draw, nx + nw, cy, cx, ny + nh, 2.0, col);
  gui::line(draw, cx, ny + nh, nx, cy, 2.0, col);
  gui::line(draw, nx, cy, cx, ny, 2.0, col);
  gui::rectBorder(draw, cx - 3.0, ny - 3.0, 6.0, 6.0, 1.0, fcWhite(), lineCol, 1.0);
  gui::rectBorder(draw, nx + nw - 3.0, cy - 3.0, 6.0, 6.0, 1.0, fcWhite(), lineCol, 1.0);
  gui::rectBorder(draw, cx - 3.0, ny + nh - 3.0, 6.0, 6.0, 1.0, fcWhite(), lineCol, 1.0);
  gui::rectBorder(draw, nx - 3.0, cy - 3.0, 6.0, 6.0, 1.0, fcWhite(), lineCol, 1.0);
}

void drawCanvasDots(Draw* draw, Rect vp, bool dark) {
  float step = 24.0;
  Color dotCol = fcCanvasDot(dark);
  float x = vp.x + 12.0;
  while (x < vp.x + vp.w) {
    float y = vp.y + 12.0;
    while (y < vp.y + vp.h) {
      gui::rect(draw, x, y, 1.5, 1.5, 0.0, dotCol);
      y = y + step;
    }
    x = x + step;
  }
}

void paintStage() {
  Draw* draw = gui::paintDraw();
  ed.canvasRect = draw.rect;

  Rect stage = computeStageScreenRect(&ed);
  ed.stageScreenX = stage.x;
  ed.stageScreenY = stage.y;
  ed.stageScreenW = stage.w;
  ed.stageScreenH = stage.h;
  refreshInspectorLabels(&ed);

  float scale = effectiveScale(&ed);
  float fx = stage.x;
  float fy = stage.y;
  float fw = stage.w;
  float fh = stage.h;

  // Background dot grid inside full-bleed canvas
  gui::pushClip(draw, draw.rect.x, draw.rect.y, draw.rect.w, draw.rect.h);
  drawCanvasDots(draw, draw.rect, ed.darkTheme);

  // Stage soft drop shadow
  gui::rect(draw, fx + 2.0, fy + 4.0, fw, fh, 4.0, gui::rgba(0, 0, 0, 22));

  // Frame title label above top-left corner (UI3 style)
  gui::text(draw, &ed.stageName[0], fx, fy - 18.0, 10.5, gui::medium(),
            pickColor(ed.selected < 0 && !ed.presentMode, fcGreenDark(), fcSecondaryText(ed.darkTheme)));

  // Stage surface fill
  if (ed.outlineMode) {
    gui::rectBorder(draw, fx, fy, fw, fh, 2.0, gui::clear(), fcSecondaryText(ed.darkTheme), 1.0);
  } else if (ed.fillVisible) {
    gui::rectBorder(draw, fx, fy, fw, fh, 2.0, ed.stageBg, fcDesignBorder(), 1.0);
  } else {
    gui::rectBorder(draw, fx, fy, fw, fh, 2.0, gui::clear(), fcBorder(ed.darkTheme), 1.0);
  }

  if (ed.clipContent) {
    gui::pushClip(draw, fx, fy, fw, fh);
  }

  // Render scene nodes
  for (int i = 0; i < ed.count; i = i + 1) {
    if (!ed.nodes[i].visible) { continue; }
    DesignNode* n = &ed.nodes[i];
    float nx = fx + n.x * scale;
    float ny = fy + n.y * scale;
    float nw = n.w * scale;
    float nh = n.h * scale;
    float nr = n.radius * scale;

    if (ed.outlineMode) {
      Color wc = pickColor(ed.selected == i, fcGreen(), fcMutedText(ed.darkTheme));
      gui::rectBorder(draw, nx, ny, nw, nh, nr, gui::clear(), wc, 1.0);
      continue;
    }

    int alpha = ((n.opacity * 255.0) + 0.5) as int;
    if (alpha < 0) { alpha = 0; }
    if (alpha > 255) { alpha = 255; }
    Color fillC = if (alpha < 255 && n.fill.a > 0) gui::fade(n.fill, alpha) else n.fill;
    Color inkC = if (alpha < 255 && n.ink.a > 0) gui::fade(n.ink, alpha) else n.ink;

    if (n.kind == (NodeKind::NodeRectangle as int) || n.kind == (NodeKind::NodeFrame as int)) {
      if (n.border > 0.0) {
        gui::rectBorder(draw, nx, ny, nw, nh, nr, fillC, n.stroke, n.border);
      } else {
        gui::rect(draw, nx, ny, nw, nh, nr, fillC);
      }
      if (n.kind == (NodeKind::NodeFrame as int)) {
        gui::text(draw, &n.name[0], nx + 6.0, ny - 14.0, 9.0, gui::medium(), fcGreenDark());
      }
    } else if (n.kind == (NodeKind::NodeButton as int)) {
      gui::rect(draw, nx, ny, nw, nh, nr, fillC);
      float ts = gui::maxf(7.5, n.textSize * scale);
      float tw = gui::textWidth(draw, &n.name[0], ts, gui::medium());
      gui::text(draw, &n.name[0], nx + (nw - tw) * 0.5, ny + (nh - ts) * 0.42, ts, gui::medium(), inkC);
    } else if (n.kind == (NodeKind::NodeText as int)) {
      GuiFont f = if (n.font == 1) gui::medium() else gui::body();
      float ts = gui::maxf(6.5, n.textSize * scale);
      gui::text(draw, &n.name[0], nx, ny, ts, f, inkC);
    } else if (n.kind == (NodeKind::NodeChart as int)) {
      drawGroupedBars(draw, nx, ny, nw, nh, scale, fillC);
    } else if (n.kind == (NodeKind::NodeDonut as int)) {
      drawSegmentedDonut(draw, nx, ny, nw, nh);
    } else if (n.kind == (NodeKind::NodeLine as int)) {
      drawTrendPolyline(draw, nx, ny, nw, nh, fillC, 0);
    } else if (n.kind == (NodeKind::NodeSparkline as int)) {
      drawTrendPolyline(draw, nx, ny, nw, nh, fillC, n.font);
    } else if (n.kind == (NodeKind::NodePen as int)) {
      drawVectorDiamond(draw, nx, ny, nw, nh, fillC, n.stroke);
    } else if (n.kind == (NodeKind::NodeComment as int)) {
      gui::rectBorder(draw, nx, ny, nw, nh, 10.0, fcNavy(), fcGreen(), 1.5);
      gui::rect(draw, nx + 10.0, ny + 8.0, 8.0, 8.0, 4.0, fcGreen());
      gui::text(draw, &n.name[0], nx + 24.0, ny + 6.0, 9.5, gui::medium(), fcWhite());
    }
  }

  // 12-column Layout Grid overlay
  if (ed.showGrid) {
    float margin = 24.0 * scale;
    float gutter = 12.0 * scale;
    float colW = (fw - margin * 2.0 - gutter * 11.0) / 12.0;
    if (colW > 2.0) {
      for (int c = 0; c < 12; c = c + 1) {
        float gx = fx + margin + (c as float) * (colW + gutter);
        gui::rect(draw, gx, fy, colW, fh, 0.0, fcLayoutGuide());
      }
    }
  }

  if (ed.clipContent) {
    gui::popClip(draw);
  }

  // Rubber-band creation preview
  if (ed.creating) {
    float rx0 = gui::minf(ed.createStartDx, ed.createCurDx);
    float ry0 = gui::minf(ed.createStartDy, ed.createCurDy);
    float rx1 = gui::maxf(ed.createStartDx, ed.createCurDx);
    float ry1 = gui::maxf(ed.createStartDy, ed.createCurDy);
    float sx = fx + rx0 * scale;
    float sy = fy + ry0 * scale;
    float sw = (rx1 - rx0) * scale;
    float sh = (ry1 - ry0) * scale;
    gui::rectBorder(draw, sx, sy, sw, sh, 4.0, gui::rgba(10, 207, 131, 32), fcGreen(), 1.5);
  }

  // Selection chrome (hidden during Present Mode)
  if (!ed.presentMode) {
    if (ed.selected < 0) {
      // FigCraft root frame signature: soft wash + quarter guides + handles
      gui::rect(draw, fx, fy, fw, fh, 2.0, fcSelectionWash());
      Color guide = fcSelectionGuide();
      gui::line(draw, fx + fw * 0.25, fy, fx + fw * 0.25, fy + fh, 1.0, guide);
      gui::line(draw, fx + fw * 0.50, fy, fx + fw * 0.50, fy + fh, 1.0, guide);
      gui::line(draw, fx + fw * 0.75, fy, fx + fw * 0.75, fy + fh, 1.0, guide);
      gui::rectBorder(draw, fx, fy, fw, fh, 0.0, gui::clear(), fcGreen(), 1.5);
      drawAllHandles(draw, fx, fy, fw, fh, 4.0, ed.darkTheme);
    } else if (ed.selected < ed.count) {
      DesignNode* sel = &ed.nodes[ed.selected];
      float sx = fx + sel.x * scale;
      float sy = fy + sel.y * scale;
      float sw = sel.w * scale;
      float sh = sel.h * scale;
      gui::rectBorder(draw, sx, sy, sw, sh, 0.0, gui::clear(), fcGreen(), 1.5);
      drawAllHandles(draw, sx, sy, sw, sh, 0.0, ed.darkTheme);
    }

    // Centered dimension pill directly beneath selected item / frame
    Rect sr = selectedScreenRect(&ed);
    float tw = gui::textWidth(draw, &ed.dimLabel[0], 8.5, gui::medium());
    float bw = tw + 16.0;
    float bx = sr.x + (sr.w - bw) * 0.5;
    float by = sr.y + sr.h + 6.0;
    gui::rect(draw, bx, by, bw, 18.0, 4.0, fcGreen());
    gui::text(draw, &ed.dimLabel[0], bx + 8.0, by + 3.0, 8.5, gui::medium(), fcWhite());
  }

  gui::popClip(draw);
}

bool mouseInsideFloatingOverlay(float mx, float my) {
  Rect tb = gui::widgetRect("fc-toolbar");
  if (tb.w > 0.0 && gui::hasPoint(tb, mx, my)) { return true; }
  Rect qa = gui::widgetRect("fc-actions-bar");
  if (qa.w > 0.0 && gui::hasPoint(qa, mx, my)) { return true; }
  Rect hc = gui::widgetRect("fc-help-card");
  if (hc.w > 0.0 && gui::hasPoint(hc, mx, my)) { return true; }
  Rect lc = gui::widgetRect("fc-expand-left");
  if (lc.w > 0.0 && gui::hasPoint(lc, mx, my)) { return true; }
  Rect pb = gui::widgetRect("fc-present-bar");
  if (pb.w > 0.0 && gui::hasPoint(pb, mx, my)) { return true; }
  return false;
}

void handleCanvasInput() {
  if (!gui::wantsKeyboard()) {
    if (gui::keyPressed(GuiKey::GuiKeyEscape)) {
      if (ed.presentMode) { ed.presentMode = false; }
      else if (ed.showHelp) { ed.showHelp = false; }
      else if (ed.showActions) { ed.showActions = false; }
      else if (ed.tool != (ToolKind::ToolMove as int)) { ed.tool = ToolKind::ToolMove as int; }
      else { ed.selected = -1; }
    }
    if (!ed.presentMode) {
      if (gui::keyPressed(GuiKey::GuiKeyV)) { selectTool(&ed, ToolKind::ToolMove as int); }
      if (gui::keyPressed(GuiKey::GuiKeyF)) { selectTool(&ed, ToolKind::ToolFrame as int); }
      if (gui::keyPressed(GuiKey::GuiKeyR)) { selectTool(&ed, ToolKind::ToolRect as int); }
      if (gui::keyPressed(GuiKey::GuiKeyP)) { selectTool(&ed, ToolKind::ToolPen as int); }
      if (gui::keyPressed(GuiKey::GuiKeyT)) { selectTool(&ed, ToolKind::ToolText as int); }
      if (gui::keyPressed(GuiKey::GuiKeyC)) { selectTool(&ed, ToolKind::ToolComment as int); }
      if (gui::keyPressed(GuiKey::GuiKeyK)) { ed.showActions = !ed.showActions; }
      if (gui::keyPressed(GuiKey::GuiKeyG)) { ed.showGrid = !ed.showGrid; }
      if (gui::keyPressed(GuiKey::GuiKeyL)) { setBottomMode(&ed, BottomMode::ModeLayout as int); }
      if (gui::keyPressed(GuiKey::GuiKeyD)) { duplicateSelectedNode(&ed); }
      if (gui::keyPressed(GuiKey::GuiKeyEqual)) { stepZoom(&ed, 1); }
      if (gui::keyPressed(GuiKey::GuiKeyMinus)) { stepZoom(&ed, -1); }
      if (gui::keyPressed(GuiKey::GuiKeyZero)) { stepZoom(&ed, 0); }
      if (gui::keyPressed(GuiKey::GuiKeyDelete) || gui::keyPressed(GuiKey::GuiKeyBackspace)) {
        deleteSelectedNode(&ed);
      }
      if (gui::keyPressed(GuiKey::GuiKeyLeft)) { nudgeSelected(&ed, -4.0, 0.0); }
      if (gui::keyPressed(GuiKey::GuiKeyRight)) { nudgeSelected(&ed, 4.0, 0.0); }
      if (gui::keyPressed(GuiKey::GuiKeyUp)) { nudgeSelected(&ed, 0.0, -4.0); }
      if (gui::keyPressed(GuiKey::GuiKeyDown)) { nudgeSelected(&ed, 0.0, 4.0); }
    }
  }

  float mx = gui::mouseX();
  float my = gui::mouseY();
  float scale = effectiveScale(&ed);
  bool inCanvas = gui::hasPoint(ed.canvasRect, mx, my) && !mouseInsideFloatingOverlay(mx, my);

  if (gui::mouseClicked() && inCanvas) {
    float dx = screenToDesignX(&ed, mx);
    float dy = screenToDesignY(&ed, my);

    if (ed.presentMode) {
      int hit = hitTestNode(&ed, dx, dy);
      if (hit >= 0 && ed.nodes[hit].kind == (NodeKind::NodeButton as int)) {
        gui::toast(&ed.nodes[hit].name[0], "Triggered prototype action.");
      } else if (ed.pageCount > 1) {
        switchPage(&ed, if (ed.activePage == 0) 1 else 0);
      }
      return;
    }

    if (gui::keyDown(GuiKey::GuiKeySpace) || gui::middleDown()) {
      ed.panning = true;
      ed.dragStartX = ed.offsetX;
      ed.dragStartY = ed.offsetY;
      ed.dragMouseX = mx;
      ed.dragMouseY = my;
      return;
    }

    if (ed.tool == (ToolKind::ToolMove as int)) {
      int h = hitTestSelectionHandle(&ed, mx, my);
      if (h != (HandleKind::HandleNone as int) && ed.selected >= 0 && ed.selected < ed.count && !ed.nodes[ed.selected].locked) {
        ed.dragging = true;
        ed.dragHandle = h;
        ed.dragStartX = ed.nodes[ed.selected].x;
        ed.dragStartY = ed.nodes[ed.selected].y;
        ed.dragStartW = ed.nodes[ed.selected].w;
        ed.dragStartH = ed.nodes[ed.selected].h;
        ed.dragMouseX = mx;
        ed.dragMouseY = my;
        return;
      }

      int hit = hitTestNode(&ed, dx, dy);
      if (hit >= 0) {
        ed.selected = hit;
        if (!ed.nodes[hit].locked) {
          ed.dragging = true;
          ed.dragHandle = HandleKind::HandleNone as int;
          ed.dragStartX = ed.nodes[hit].x;
          ed.dragStartY = ed.nodes[hit].y;
          ed.dragMouseX = mx;
          ed.dragMouseY = my;
        }
      } else {
        ed.selected = -1;
        ed.panning = true;
        ed.dragStartX = ed.offsetX;
        ed.dragStartY = ed.offsetY;
        ed.dragMouseX = mx;
        ed.dragMouseY = my;
      }
      refreshInspectorLabels(&ed);
    } else if (ed.tool == (ToolKind::ToolFrame as int) || ed.tool == (ToolKind::ToolRect as int)) {
      ed.creating = true;
      ed.createStartDx = dx;
      ed.createStartDy = dy;
      ed.createCurDx = dx;
      ed.createCurDy = dy;
    } else if (ed.tool == (ToolKind::ToolPen as int)) {
      addNodeToEditor(&ed, NodeKind::NodePen, "Vector Path", "",
                      dx - 45.0, dy - 45.0, 90.0, 90.0,
                      fcGreen(), gui::clear(), fcGreenDark(), 0.0, 2.0, 0.0, 0);
      ed.selected = ed.count - 1;
      ed.tool = ToolKind::ToolMove as int;
      refreshInspectorLabels(&ed);
    } else if (ed.tool == (ToolKind::ToolText as int)) {
      addScText(&ed, "New Heading", dx, dy, 180.0, 32.0, 18.0, fcNavy(), 1);
      ed.selected = ed.count - 1;
      ed.tool = ToolKind::ToolMove as int;
      refreshInspectorLabels(&ed);
    } else if (ed.tool == (ToolKind::ToolComment as int)) {
      addNodeToEditor(&ed, NodeKind::NodeComment, "Review Note", "Looks crisp!",
                      dx, dy, 136.0, 28.0,
                      fcNavy(), fcWhite(), fcGreen(), 10.0, 1.5, 10.0, 1);
      ed.selected = ed.count - 1;
      ed.tool = ToolKind::ToolMove as int;
      refreshInspectorLabels(&ed);
    }
  }

  if (ed.creating) {
    if (gui::mouseDown()) {
      ed.createCurDx = screenToDesignX(&ed, mx);
      ed.createCurDy = screenToDesignY(&ed, my);
    } else {
      ed.creating = false;
      float rx0 = gui::minf(ed.createStartDx, ed.createCurDx);
      float ry0 = gui::minf(ed.createStartDy, ed.createCurDy);
      float rw = gui::maxf(ed.createStartDx, ed.createCurDx) - rx0;
      float rh = gui::maxf(ed.createStartDy, ed.createCurDy) - ry0;
      if (rw < 18.0 && rh < 18.0) {
        rw = if (ed.tool == (ToolKind::ToolFrame as int)) 320.0 else 160.0;
        rh = if (ed.tool == (ToolKind::ToolFrame as int)) 220.0 else 100.0;
      }
      if (ed.tool == (ToolKind::ToolFrame as int)) {
        addNodeToEditor(&ed, NodeKind::NodeFrame, "Frame", "",
                        rx0, ry0, rw, rh, fcWhite(), gui::clear(), fcBorder(ed.darkTheme), 6.0, 1.0, 0.0, 0);
      } else {
        addScRect(&ed, "Rectangle", rx0, ry0, rw, rh, fcGreen(), 8.0, 0.0, gui::clear());
      }
      ed.selected = ed.count - 1;
      ed.tool = ToolKind::ToolMove as int;
      refreshInspectorLabels(&ed);
    }
  }

  if (ed.dragging) {
    if (gui::mouseDown()) {
      if (ed.selected >= 0 && ed.selected < ed.count) {
        float ddx = (mx - ed.dragMouseX) / scale;
        float ddy = (my - ed.dragMouseY) / scale;
        if (ed.dragHandle != (HandleKind::HandleNone as int)) {
          Rect nr = applyResizeDelta(ed.dragStartX, ed.dragStartY, ed.dragStartW, ed.dragStartH,
                                     ed.dragHandle, ddx, ddy, 16.0);
          ed.nodes[ed.selected].x = nr.x;
          ed.nodes[ed.selected].y = nr.y;
          ed.nodes[ed.selected].w = nr.w;
          ed.nodes[ed.selected].h = nr.h;
        } else {
          ed.nodes[ed.selected].x = ed.dragStartX + ddx;
          ed.nodes[ed.selected].y = ed.dragStartY + ddy;
        }
        refreshInspectorLabels(&ed);
      }
    } else {
      ed.dragging = false;
      ed.dragHandle = HandleKind::HandleNone as int;
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
