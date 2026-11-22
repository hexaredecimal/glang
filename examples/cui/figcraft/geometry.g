// FigCraft Geometry, Coordinate Transforms, Hit Testing, and Alignment Math.
// Pure functions with zero CUI side effects for straightforward unit testing.

import std.gui;
import std.cui;
import examples.cui.figcraft.palette;
import examples.cui.figcraft.model;

float baseStageScale(float canvasW, float canvasH, float stageW, float stageH) {
  if (stageW <= 0.0 || stageH <= 0.0) { return 0.566667; }
  float availW = canvasW - 24.0;
  float availH = canvasH - 110.0;
  if (availW < 240.0) { availW = 240.0; }
  if (availH < 180.0) { availH = 180.0; }
  float sx = availW / stageW;
  float sy = availH / stageH;
  float s = gui::minf(sx, sy);
  return gui::clampf(s, 0.2, 1.5);
}

float effectiveScale(Editor* e) {
  float base = baseStageScale(e.canvasRect.w, e.canvasRect.h, e.stageW, e.stageH);
  return base * e.zoom;
}

Rect computeStageScreenRect(Editor* e) {
  float scale = effectiveScale(e);
  float sw = e.stageW * scale;
  float sh = e.stageH * scale;
  float topReserve = 12.0;
  float botReserve = 76.0;
  float cx = e.canvasRect.x + (e.canvasRect.w - sw) * 0.5 + e.offsetX;
  float cy = e.canvasRect.y + topReserve + (e.canvasRect.h - topReserve - botReserve - sh) * 0.5 + e.offsetY;
  return Rect{x: cx, y: cy, w: sw, h: sh};
}

float designToScreenX(Editor* e, float dx) {
  return e.stageScreenX + dx * effectiveScale(e);
}

float designToScreenY(Editor* e, float dy) {
  return e.stageScreenY + dy * effectiveScale(e);
}

float screenToDesignX(Editor* e, float sx) {
  float scale = effectiveScale(e);
  if (scale <= 0.0001) { return 0.0; }
  return (sx - e.stageScreenX) / scale;
}

float screenToDesignY(Editor* e, float sy) {
  float scale = effectiveScale(e);
  if (scale <= 0.0001) { return 0.0; }
  return (sy - e.stageScreenY) / scale;
}

int hitTestNode(Editor* e, float dx, float dy) {
  for (int i = e.count - 1; i >= 0; i = i - 1) {
    if (!e.nodes[i].visible) { continue; }
    if (dx >= e.nodes[i].x && dx <= e.nodes[i].x + e.nodes[i].w &&
        dy >= e.nodes[i].y && dy <= e.nodes[i].y + e.nodes[i].h) {
      return i;
    }
  }
  return -1;
}

bool nearHandle(float mx, float my, float hx, float hy, float tol) {
  float dx = mx - hx;
  if (dx < 0.0) { dx = -dx; }
  float dy = my - hy;
  if (dy < 0.0) { dy = -dy; }
  return dx <= tol && dy <= tol;
}

Rect selectedScreenRect(Editor* e) {
  if (e.selected >= 0 && e.selected < e.count) {
    float scale = effectiveScale(e);
    return Rect{
      x: e.stageScreenX + e.nodes[e.selected].x * scale,
      y: e.stageScreenY + e.nodes[e.selected].y * scale,
      w: e.nodes[e.selected].w * scale,
      h: e.nodes[e.selected].h * scale
    };
  }
  return Rect{
    x: e.stageScreenX,
    y: e.stageScreenY,
    w: e.stageScreenW,
    h: e.stageScreenH
  };
}

int hitTestSelectionHandle(Editor* e, float mx, float my) {
  Rect r = selectedScreenRect(e);
  float tol = 7.5;
  float inset = if (e.selected < 0) 4.0 else 0.0;
  float l = r.x + inset;
  float ri = r.x + r.w - inset;
  float t = r.y + inset;
  float b = r.y + r.h - inset;
  float cx = r.x + r.w * 0.5;
  float cy = r.y + r.h * 0.5;

  if (nearHandle(mx, my, l, t, tol)) { return HandleKind::HandleTL as int; }
  if (nearHandle(mx, my, ri, t, tol)) { return HandleKind::HandleTR as int; }
  if (nearHandle(mx, my, l, b, tol)) { return HandleKind::HandleBL as int; }
  if (nearHandle(mx, my, ri, b, tol)) { return HandleKind::HandleBR as int; }
  if (nearHandle(mx, my, cx, t, tol)) { return HandleKind::HandleT as int; }
  if (nearHandle(mx, my, cx, b, tol)) { return HandleKind::HandleB as int; }
  if (nearHandle(mx, my, l, cy, tol)) { return HandleKind::HandleL as int; }
  if (nearHandle(mx, my, ri, cy, tol)) { return HandleKind::HandleR as int; }
  return HandleKind::HandleNone as int;
}

Rect applyResizeDelta(float startX, float startY, float startW, float startH,
                      int handle, float deltaX, float deltaY, float minSize) {
  float x = startX;
  float y = startY;
  float w = startW;
  float h = startH;

  bool hasL = handle == (HandleKind::HandleTL as int) ||
              handle == (HandleKind::HandleBL as int) ||
              handle == (HandleKind::HandleL as int);
  bool hasR = handle == (HandleKind::HandleTR as int) ||
              handle == (HandleKind::HandleBR as int) ||
              handle == (HandleKind::HandleR as int);
  bool hasT = handle == (HandleKind::HandleTL as int) ||
              handle == (HandleKind::HandleT as int) ||
              handle == (HandleKind::HandleTR as int);
  bool hasB = handle == (HandleKind::HandleBL as int) ||
              handle == (HandleKind::HandleB as int) ||
              handle == (HandleKind::HandleBR as int);

  if (hasL) {
    float maxDelta = startW - minSize;
    float d = if (deltaX > maxDelta) maxDelta else deltaX;
    x = startX + d;
    w = startW - d;
  } else if (hasR) {
    w = startW + deltaX;
    if (w < minSize) { w = minSize; }
  }

  if (hasT) {
    float maxDeltaY = startH - minSize;
    float d = if (deltaY > maxDeltaY) maxDeltaY else deltaY;
    y = startY + d;
    h = startH - d;
  } else if (hasB) {
    h = startH + deltaY;
    if (h < minSize) { h = minSize; }
  }

  return Rect{x: x, y: y, w: w, h: h};
}

Rect computeAlignedPos(float stageW, float stageH, float nodeW, float nodeH,
                       int alignMode, float curX, float curY) {
  float nx = curX;
  float ny = curY;
  if (alignMode == 0) { nx = 0.0; }
  else if (alignMode == 1) { nx = (stageW - nodeW) * 0.5; }
  else if (alignMode == 2) { nx = stageW - nodeW; }
  else if (alignMode == 3) { ny = 0.0; }
  else if (alignMode == 4) { ny = (stageH - nodeH) * 0.5; }
  else if (alignMode == 5) { ny = stageH - nodeH; }
  return Rect{x: nx, y: ny, w: nodeW, h: nodeH};
}

const char* nodeGlyph(int kind) {
  if (kind == (NodeKind::NodeText as int)) { return std::cui::icons::textTool(); }
  if (kind == (NodeKind::NodeChart as int)) { return std::cui::icons::chartBar(); }
  if (kind == (NodeKind::NodeLine as int)) { return std::cui::icons::activity(); }
  if (kind == (NodeKind::NodeSparkline as int)) { return std::cui::icons::activity(); }
  if (kind == (NodeKind::NodeDonut as int)) { return std::cui::icons::chartLine(); }
  if (kind == (NodeKind::NodeButton as int)) { return std::cui::icons::circle(); }
  if (kind == (NodeKind::NodePen as int)) { return std::cui::icons::pencil(); }
  if (kind == (NodeKind::NodeComment as int)) { return std::cui::icons::message(); }
  if (kind == (NodeKind::NodeFrame as int)) { return std::cui::icons::grid(); }
  return std::cui::icons::square();
}

const char* nodeKindLabel(int kind) {
  if (kind == (NodeKind::NodeText as int)) { return "Text"; }
  if (kind == (NodeKind::NodeChart as int)) { return "Bar Chart"; }
  if (kind == (NodeKind::NodeLine as int)) { return "Trend Line"; }
  if (kind == (NodeKind::NodeSparkline as int)) { return "Sparkline"; }
  if (kind == (NodeKind::NodeDonut as int)) { return "Donut Chart"; }
  if (kind == (NodeKind::NodeButton as int)) { return "Button"; }
  if (kind == (NodeKind::NodePen as int)) { return "Vector"; }
  if (kind == (NodeKind::NodeComment as int)) { return "Comment"; }
  if (kind == (NodeKind::NodeFrame as int)) { return "Frame"; }
  return "Rectangle";
}

void refreshInspectorLabels(Editor* e) {
  formatPercent(&e.zoomLabel[0], effectiveScale(e), 16);
  formatInt(&e.layerCountLabel[0], e.count, 16);

  if (e.selected >= 0 && e.selected < e.count) {
    DesignNode* n = &e.nodes[e.selected];
    formatDims(&e.dimLabel[0], (n.w + 0.5) as int, (n.h + 0.5) as int, 32);
    Color fc = if (n.fill.a > 0) n.fill else n.ink;
    formatHexColor(&e.hexLabel[0], fc, 16);
    formatDegree(&e.degLabel[0], n.rotation, 24);
    formatPercent(&e.opacityLabel[0], n.opacity, 24);
  } else {
    formatDims(&e.dimLabel[0], (e.stageW + 0.5) as int, (e.stageH + 0.5) as int, 32);
    formatHexColor(&e.hexLabel[0], e.stageBg, 16);
    formatDegree(&e.degLabel[0], 0.0, 24);
    formatPercent(&e.opacityLabel[0], 1.0, 24);
  }
}
