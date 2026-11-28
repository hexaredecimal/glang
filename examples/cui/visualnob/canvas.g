// VisualNob Interactive Node Canvas:
// Custom Bezier wire rendering, typed socket primitives (Exec diamonds + Data circles),
// node card painting, drag-to-connect, pan/zoom, context menu triggers, and shortcuts.

import std.gui;
import std.cui;
import examples.cui.visualnob.palette;
import examples.cui.visualnob.model;
import examples.cui.visualnob.geometry;
import examples.cui.visualnob.graph;
import examples.cui.visualnob.runtime;

void drawSocketShape(Draw* draw, float sx, float sy, float r, int pinType,
                     bool filled, bool hovered, bool compatRing, bool dark) {
  Color col = pinTypeColor(pinType, dark);
  Color bg = vnCard(dark);

  if (hovered) {
    gui::circle(draw, sx, sy, r + 5.0, gui::fade(col, 65));
  } else if (compatRing) {
    gui::circleBorder(draw, sx, sy, r + 4.5, gui::clear(), col, 1.4);
  }

  if (pinType == (PinType::PinExec as int)) {
    Color fillCol = if (filled) col else bg;
    gui::diamond(draw, sx, sy, r + 1.0, fillCol, col, 1.8);
  } else {
    Color fillCol = if (filled) col else bg;
    gui::circleBorder(draw, sx, sy, r, fillCol, col, 1.8);
  }
}

void drawWireWithArrow(Draw* draw, GraphEditor* e, int wireIdx, bool dark) {
  Wire* w = &e.wires[wireIdx];
  Vec2 p0 = outputPortScreenPos(e, w.fromNode, w.fromPort);
  Vec2 p1 = inputPortScreenPos(e, w.toNode, w.toPort);

  bool isSel = e.selectedWire == wireIdx;
  bool isHov = e.hoverWire == wireIdx;
  Color baseCol = pinTypeColor(w.pinType, dark);
  Color wireCol = baseCol;
  float thick = 2.4 * gui::clampf(e.zoom, 0.7, 1.25);

  if (w.active) {
    gui::wireCurve(draw, p0.x, p0.y, p1.x, p1.y, thick + 4.0, gui::fade(vnMint(), 65));
    wireCol = if (w.pinType == (PinType::PinExec as int)) vnMint() else baseCol;
    thick = thick + 0.8;
  } else if (isSel || isHov) {
    gui::wireCurve(draw, p0.x, p0.y, p1.x, p1.y, thick + 3.5, gui::fade(baseCol, 85));
    thick = thick + 1.0;
  } else {
    gui::wireCurve(draw, p0.x, p0.y + 1.5, p1.x, p1.y + 1.5, thick + 1.0, gui::rgba(0, 0, 0, 45));
  }

  gui::wireCurve(draw, p0.x, p0.y, p1.x, p1.y, thick, wireCol);

  // Midpoint directional arrow
  float dx = gui::absf(p1.x - p0.x);
  float dy = gui::absf(p1.y - p0.y);
  float handle = gui::maxf(48.0, dx * 0.48);
  if (p1.x < p0.x) {
    handle = gui::maxf(72.0, gui::minf(180.0, dx * 0.55 + dy * 0.25));
  }
  float mx0 = gui::bezierEval(p0.x, p0.x + handle, p1.x - handle, p1.x, 0.48);
  float my0 = gui::bezierEval(p0.y, p0.y, p1.y, p1.y, 0.48);
  float mx1 = gui::bezierEval(p0.x, p0.x + handle, p1.x - handle, p1.x, 0.54);
  float my1 = gui::bezierEval(p0.y, p0.y, p1.y, p1.y, 0.54);
  gui::arrowHead(draw, mx1, my1, mx1 - mx0, my1 - my0, 6.5 * gui::clampf(e.zoom, 0.75, 1.2), wireCol);
}

void buildNodeSummaryLabel(ScriptNode* n, char* out, int cap) {
  out[0] = '\0';
  int k = n.kind;
  if (k == (VnNodeKind::VnConstNumber as int)) {
    vnCopyStr(out, "val = ", cap);
    char[24] nb;
    vnFormatNum(&nb[0], n.numValue, 24);
    vnAppendStr(out, &nb[0], cap);
  } else if (k == (VnNodeKind::VnConstString as int)) {
    vnCopyStr(out, "\"", cap);
    vnAppendStr(out, &n.strValue[0], cap);
    vnAppendStr(out, "\"", cap);
  } else if (k == (VnNodeKind::VnConstBool as int)) {
    vnCopyStr(out, if (n.boolValue) "true" else "false", cap);
  } else if (k == (VnNodeKind::VnGetVar as int) || k == (VnNodeKind::VnSetVar as int)) {
    vnCopyStr(out, "$", cap);
    vnAppendStr(out, &n.strValue[0], cap);
  } else if (k == (VnNodeKind::VnCompare as int)) {
    if (n.opMode == 0) { vnCopyStr(out, "op: A > B", cap); }
    else if (n.opMode == 1) { vnCopyStr(out, "op: A >= B", cap); }
    else if (n.opMode == 2) { vnCopyStr(out, "op: A < B", cap); }
    else if (n.opMode == 3) { vnCopyStr(out, "op: A <= B", cap); }
    else if (n.opMode == 4) { vnCopyStr(out, "op: A == B", cap); }
    else { vnCopyStr(out, "op: A != B", cap); }
  } else if (k == (VnNodeKind::VnMathAdd as int)) {
    vnCopyStr(out, if (n.opMode == 1) "op: A - B" else "op: A + B", cap);
  } else if (k == (VnNodeKind::VnMathMul as int)) {
    if (n.opMode == 1) { vnCopyStr(out, "op: A / B", cap); }
    else if (n.opMode == 2) { vnCopyStr(out, "op: A % B", cap); }
    else { vnCopyStr(out, "op: A * B", cap); }
  }
}

void drawScriptNodeCard(Draw* draw, GraphEditor* e, int nodeIdx, bool dark) {
  ScriptNode* n = &e.nodes[nodeIdx];
  float z = e.zoom;
  float sx = worldToScreenX(e, n.x);
  float sy = worldToScreenY(e, n.y);
  float sw = n.w * z;
  float nh = computeNodeHeight(n);
  float sh = nh * z;
  float rad = 8.0 * z;

  bool isSel = e.selectedNode == nodeIdx;
  bool isHov = e.hoverNode == nodeIdx;
  Color headerCol = categoryHeaderColor(n.category, dark);

  if (n.kind == (VnNodeKind::VnComment as int)) {
    Color noteBg = if (dark) gui::rgba(78, 62, 26, 220) else gui::rgba(255, 246, 212, 240);
    Color noteBorder = if (isSel) vnMint() else vnAmber();
    gui::rect(draw, sx + 2.0, sy + 3.0, sw, sh, rad, vnNodeShadow(dark));
    gui::rectBorder(draw, sx, sy, sw, sh, rad, noteBg, noteBorder, if (isSel) 2.0 else 1.2);
    float ts = gui::maxf(8.0, 10.5 * z);
    gui::text(draw, &n.title[0], sx + 10.0 * z, sy + 8.0 * z, ts, gui::medium(), vnAmber());
    gui::pushClip(draw, sx + 8.0 * z, sy + 26.0 * z, sw - 16.0 * z, sh - 32.0 * z);
    gui::text(draw, &n.strValue[0], sx + 10.0 * z, sy + 28.0 * z, gui::maxf(7.5, 9.5 * z), gui::body(), vnText(dark));
    gui::popClip(draw);
    return;
  }

  // Drop shadow + outer selection/execution ring
  gui::rect(draw, sx + 2.0, sy + 4.0, sw, sh, rad, vnNodeShadow(dark));
  if (n.executed && e.hasRun) {
    gui::rectBorder(draw, sx - 2.0, sy - 2.0, sw + 4.0, sh + 4.0, rad + 2.0,
                    gui::clear(), gui::fade(vnMint(), 170), 2.0);
  }
  if (isSel) {
    gui::rectBorder(draw, sx - 2.5, sy - 2.5, sw + 5.0, sh + 5.0, rad + 2.5,
                    gui::clear(), vnMint(), 2.0);
  } else if (isHov) {
    gui::rectBorder(draw, sx - 1.5, sy - 1.5, sw + 3.0, sh + 3.0, rad + 1.5,
                    gui::clear(), gui::fade(headerCol, 150), 1.2);
  }

  // Main card surface
  Color cardBg = vnCard(dark);
  Color cardBorder = if (isSel) vnMint() else vnBorder(dark);
  gui::rectBorder(draw, sx, sy, sw, sh, rad, cardBg, cardBorder, 1.0);

  // Colored top header band (rounded top corners only)
  float hh = nodeHeaderH() * z;
  gui::rectCorners(draw, sx + 1.0, sy + 1.0, sw - 2.0, hh,
                   gui::maxf(2.0, rad - 1.0), gui::maxf(2.0, rad - 1.0), 0.0, 0.0, headerCol);

  float titleSize = gui::maxf(8.5, 11.0 * z);
  gui::icon(draw, nodeKindIcon(n.kind), sx + 9.0 * z, sy + 7.5 * z, titleSize + 1.0, vnWhite());
  gui::pushClip(draw, sx + 26.0 * z, sy, sw - 52.0 * z, hh);
  gui::text(draw, &n.title[0], sx + 27.0 * z, sy + 6.5 * z, titleSize, gui::medium(), vnWhite());
  gui::popClip(draw);

  if (n.executed && e.hasRun) {
    gui::icon(draw, std::cui::icons::checkCircle(), sx + sw - 20.0 * z, sy + 7.5 * z, titleSize, vnWhite());
  }

  if (n.collapsed) { return; }

  float portRadius = gui::maxf(4.2, 5.2 * z);
  float pinFont = gui::maxf(7.5, 9.8 * z);

  // Input ports (left edge)
  for (int p = 0; p < n.inputCount; p = p + 1) {
    Vec2 pt = inputPortScreenPos(e, nodeIdx, p);
    bool hovered = e.hoverPortNode == nodeIdx && !e.hoverPortIsOut && e.hoverPortIdx == p;
    bool compat = e.linking && e.linkFromOutput && e.linkStartNode != nodeIdx &&
                  pinsCompatible(e.linkPinType, n.inputs[p].pinType);
    bool connected = inputPortHasWire(e, nodeIdx, p);

    drawSocketShape(draw, pt.x, pt.y, portRadius, n.inputs[p].pinType,
                    connected, hovered, compat, dark);
    gui::text(draw, &n.inputs[p].label[0],
              pt.x + 11.0 * z, pt.y - pinFont * 0.62,
              pinFont, gui::body(), vnSecondaryText(dark));
  }

  // Output ports (right edge)
  for (int p = 0; p < n.outputCount; p = p + 1) {
    Vec2 pt = outputPortScreenPos(e, nodeIdx, p);
    bool hovered = e.hoverPortNode == nodeIdx && e.hoverPortIsOut && e.hoverPortIdx == p;
    bool compat = e.linking && !e.linkFromOutput && e.linkStartNode != nodeIdx &&
                  pinsCompatible(n.outputs[p].pinType, e.linkPinType);
    bool connected = outputPortHasWire(e, nodeIdx, p);

    drawSocketShape(draw, pt.x, pt.y, portRadius, n.outputs[p].pinType,
                    connected, hovered, compat, dark);
    float lw = gui::textWidth(draw, &n.outputs[p].label[0], pinFont, gui::body());
    gui::text(draw, &n.outputs[p].label[0],
              pt.x - lw - 11.0 * z, pt.y - pinFont * 0.62,
              pinFont, gui::body(), vnText(dark));
  }

  // Inline parameter chip at bottom of node body
  char[48] sum;
  buildNodeSummaryLabel(n, &sum[0], 48);
  if (sum[0] != '\0') {
    float pillY = sy + sh - 24.0 * z;
    float pillH = 17.0 * z;
    gui::rectBorder(draw, sx + 8.0 * z, pillY, sw - 16.0 * z, pillH, 4.0 * z,
                    vnField(dark), vnDivider(dark), 1.0);
    gui::pushClip(draw, sx + 12.0 * z, pillY, sw - 24.0 * z, pillH);
    gui::text(draw, &sum[0], sx + 13.0 * z, pillY + 2.5 * z,
              gui::maxf(7.5, 9.0 * z), gui::mono(), vnText(dark));
    gui::popClip(draw);
  }
}

void drawMinimapOverlay(Draw* draw, GraphEditor* e, bool dark) {
  if (!e.showMinimap || e.nodeCount == 0) { return; }
  float mw = 148.0;
  float mh = 96.0;
  float mx = e.canvasRect.x + e.canvasRect.w - mw - 14.0;
  float my = e.canvasRect.y + e.canvasRect.h - mh - 14.0;

  gui::rectBorder(draw, mx, my, mw, mh, 8.0,
                  gui::fade(vnPanel(dark), 232), vnBorder(dark), 1.0);

  float minX = e.nodes[0].x;
  float minY = e.nodes[0].y;
  float maxX = e.nodes[0].x + e.nodes[0].w;
  float maxY = e.nodes[0].y + computeNodeHeight(&e.nodes[0]);
  for (int i = 1; i < e.nodeCount; i = i + 1) {
    float h = computeNodeHeight(&e.nodes[i]);
    if (e.nodes[i].x < minX) { minX = e.nodes[i].x; }
    if (e.nodes[i].y < minY) { minY = e.nodes[i].y; }
    if (e.nodes[i].x + e.nodes[i].w > maxX) { maxX = e.nodes[i].x + e.nodes[i].w; }
    if (e.nodes[i].y + h > maxY) { maxY = e.nodes[i].y + h; }
  }
  minX = minX - 60.0; minY = minY - 40.0;
  maxX = maxX + 60.0; maxY = maxY + 40.0;
  float spanW = gui::maxf(320.0, maxX - minX);
  float spanH = gui::maxf(200.0, maxY - minY);
  float pad = 8.0;
  float s = gui::minf((mw - pad * 2.0) / spanW, (mh - pad * 2.0) / spanH);

  // Mini nodes
  for (int i = 0; i < e.nodeCount; i = i + 1) {
    float nx = mx + pad + (e.nodes[i].x - minX) * s;
    float ny = my + pad + (e.nodes[i].y - minY) * s;
    float nw = gui::maxf(5.0, e.nodes[i].w * s);
    float nh = gui::maxf(4.0, computeNodeHeight(&e.nodes[i]) * s);
    Color nc = if (e.selectedNode == i) vnMint() else categoryHeaderColor(e.nodes[i].category, dark);
    gui::rect(draw, nx, ny, nw, nh, 1.5, nc);
  }

  // Current viewport box
  float vx0 = screenToWorldX(e, e.canvasRect.x);
  float vy0 = screenToWorldY(e, e.canvasRect.y);
  float vx1 = screenToWorldX(e, e.canvasRect.x + e.canvasRect.w);
  float vy1 = screenToWorldY(e, e.canvasRect.y + e.canvasRect.h);
  float rx = gui::clampf(mx + pad + (vx0 - minX) * s, mx + 2.0, mx + mw - 6.0);
  float ry = gui::clampf(my + pad + (vy0 - minY) * s, my + 2.0, my + mh - 6.0);
  float rw = gui::clampf((vx1 - vx0) * s, 8.0, mx + mw - 2.0 - rx);
  float rh = gui::clampf((vy1 - vy0) * s, 8.0, my + mh - 2.0 - ry);
  gui::rectBorder(draw, rx, ry, rw, rh, 2.0, gui::fade(vnMint(), 24), vnMint(), 1.0);
}

void paintNodeCanvas() {
  Draw* draw = gui::paintDraw();
  vn.canvasRect = draw.rect;
  bool dark = vn.darkTheme;

  gui::pushClip(draw, draw.rect.x, draw.rect.y, draw.rect.w, draw.rect.h);
  gui::rect(draw, draw.rect.x, draw.rect.y, draw.rect.w, draw.rect.h, 0.0, vnCanvasBg(dark));

  // Grid background synced with pan & zoom
  if (vn.showGrid) {
    float step = gui::maxf(12.0, 24.0 * vn.zoom);
    gui::gridLines(draw, draw.rect.x, draw.rect.y, draw.rect.w, draw.rect.h,
                   step, vn.panX, vn.panY,
                   vnGridMinor(dark), vnGridMajor(dark), 4);
    gui::gridDots(draw, draw.rect.x, draw.rect.y, draw.rect.w, draw.rect.h,
                  step * 2.0, vn.panX, vn.panY, 1.2, vnGridDot(dark));
  }

  // Wires layer behind nodes
  for (int i = 0; i < vn.wireCount; i = i + 1) {
    drawWireWithArrow(draw, &vn, i, dark);
  }

  // Live wire preview during drag-to-connect
  if (vn.linking && vn.linkStartNode >= 0 && vn.linkStartNode < vn.nodeCount) {
    Vec2 sp = if (vn.linkFromOutput)
      outputPortScreenPos(&vn, vn.linkStartNode, vn.linkStartPort)
    else
      inputPortScreenPos(&vn, vn.linkStartNode, vn.linkStartPort);

    Color lineCol = pinTypeColor(vn.linkPinType, dark);
    if (vn.linkFromOutput) {
      gui::wireCurve(draw, sp.x, sp.y, vn.linkCurX, vn.linkCurY, 2.8, lineCol);
    } else {
      gui::wireCurve(draw, vn.linkCurX, vn.linkCurY, sp.x, sp.y, 2.8, lineCol);
    }
    gui::circle(draw, vn.linkCurX, vn.linkCurY, 4.5, lineCol);
  }

  // Nodes layer
  for (int i = 0; i < vn.nodeCount; i = i + 1) {
    drawScriptNodeCard(draw, &vn, i, dark);
  }

  // Empty-canvas hint if user cleared all nodes
  if (vn.nodeCount == 0) {
    const char* emptyTxt = "Right-click canvas or press Tab to add VisualNob nodes";
    float tw = gui::textWidth(draw, emptyTxt, 12.0, gui::medium());
    gui::text(draw, emptyTxt,
              draw.rect.x + (draw.rect.w - tw) * 0.5,
              draw.rect.y + draw.rect.h * 0.48,
              12.0, gui::medium(), vnMutedText(dark));
  }

  // Compact minimap in bottom-right corner
  drawMinimapOverlay(draw, &vn, dark);

  gui::popClip(draw);
}

bool mouseInsideVnOverlay(float mx, float my) {
  Rect cm = gui::widgetRect("vn-context-menu");
  if (cm.w > 0.0 && gui::hasPoint(cm, mx, my)) { return true; }
  Rect qa = gui::widgetRect("vn-quick-add");
  if (qa.w > 0.0 && gui::hasPoint(qa, mx, my)) { return true; }
  Rect hc = gui::widgetRect("vn-help-card");
  if (hc.w > 0.0 && gui::hasPoint(hc, mx, my)) { return true; }
  Rect lc = gui::widgetRect("vn-expand-left");
  if (lc.w > 0.0 && gui::hasPoint(lc, mx, my)) { return true; }
  return false;
}

void dismissPopups(GraphEditor* e) {
  e.contextKind = ContextKind::CtxNone as int;
  e.showQuickAdd = false;
}

void openQuickAddAt(GraphEditor* e, float sx, float sy) {
  e.contextKind = ContextKind::CtxNone as int;
  e.showQuickAdd = true;
  e.quickAddScreenX = gui::clampf(sx - e.canvasRect.x, 12.0, gui::maxf(20.0, e.canvasRect.w - 252.0));
  e.quickAddScreenY = gui::clampf(sy - e.canvasRect.y, 12.0, gui::maxf(20.0, e.canvasRect.h - 320.0));
  e.quickAddWorldX = screenToWorldX(e, sx);
  e.quickAddWorldY = screenToWorldY(e, sy);
  e.quickAddFilter[0] = '\0';
}

void handleNodeCanvasInput() {
  float mx = gui::mouseX();
  float my = gui::mouseY();
  bool inCanvas = gui::hasPoint(vn.canvasRect, mx, my);
  bool overPopup = mouseInsideVnOverlay(mx, my);

  // Keyboard shortcuts
  if (!gui::wantsKeyboard()) {
    if (gui::keyPressed(GuiKey::GuiKeyEscape)) {
      if (vn.linking) {
        vn.linking = false;
      } else if (vn.contextKind != (ContextKind::CtxNone as int) || vn.showQuickAdd) {
        dismissPopups(&vn);
      } else if (vn.showHelp) {
        vn.showHelp = false;
      } else {
        vn.selectedNode = -1;
        vn.selectedWire = -1;
      }
    }
    if (gui::keyPressed(GuiKey::GuiKeyTab)) {
      if (vn.showQuickAdd) {
        vn.showQuickAdd = false;
      } else {
        float qx = if (inCanvas) mx else (vn.canvasRect.x + vn.canvasRect.w * 0.45);
        float qy = if (inCanvas) my else (vn.canvasRect.y + vn.canvasRect.h * 0.35);
        openQuickAddAt(&vn, qx, qy);
      }
    }
    if (gui::keyPressed(GuiKey::GuiKeyR)) { runFullScript(&vn); }
    if (gui::keyPressed(GuiKey::GuiKeyT)) { triggerTick(&vn); }
    if (gui::keyPressed(GuiKey::GuiKeyG)) { vn.snapToGrid = !vn.snapToGrid; }
    if (gui::keyPressed(GuiKey::GuiKeyM)) { vn.showMinimap = !vn.showMinimap; }
    if (gui::keyPressed(GuiKey::GuiKeyD) && vn.selectedNode >= 0) {
      duplicateNodeAt(&vn, vn.selectedNode);
    }
    if (gui::keyPressed(GuiKey::GuiKeyDelete) || gui::keyPressed(GuiKey::GuiKeyBackspace)) {
      if (vn.selectedWire >= 0) {
        removeWireAt(&vn, vn.selectedWire);
      } else if (vn.selectedNode >= 0) {
        deleteNodeAt(&vn, vn.selectedNode);
      }
    }
    if (gui::keyPressed(GuiKey::GuiKeyEqual)) { stepZoomGraph(&vn, 1); }
    if (gui::keyPressed(GuiKey::GuiKeyMinus)) { stepZoomGraph(&vn, -1); }
    if (gui::keyPressed(GuiKey::GuiKeyZero)) { stepZoomGraph(&vn, 0); }
    if (gui::keyPressed(GuiKey::GuiKeyA)) { autoArrangeGraph(&vn); }
  }

  // Update hover states every frame when cursor is on the canvas
  if (inCanvas && !overPopup) {
    PortHit ph = hitTestPort(&vn, mx, my);
    if (ph.found) {
      vn.hoverPortNode = ph.nodeIdx;
      vn.hoverPortIdx = ph.portIdx;
      vn.hoverPortIsOut = ph.isOutput;
      vn.hoverNode = ph.nodeIdx;
      vn.hoverWire = -1;
    } else {
      vn.hoverPortNode = -1;
      vn.hoverPortIdx = -1;
      float wx = screenToWorldX(&vn, mx);
      float wy = screenToWorldY(&vn, my);
      int nh = hitTestNodeCard(&vn, wx, wy);
      vn.hoverNode = nh;
      if (nh < 0) {
        vn.hoverWire = hitTestWire(&vn, mx, my);
      } else {
        vn.hoverWire = -1;
      }
    }
  } else {
    vn.hoverPortNode = -1;
    vn.hoverPortIdx = -1;
    vn.hoverWire = -1;
  }

  // Dismiss menus on outside click
  if ((vn.contextKind != (ContextKind::CtxNone as int) || vn.showQuickAdd) &&
      (gui::mouseClicked() || gui::rightClicked()) && !overPopup) {
    dismissPopups(&vn);
  }

  // Right-click context menu dispatch on canvas / port / node / wire
  if (gui::rightClicked() && inCanvas && !overPopup) {
    vn.showQuickAdd = false;
    vn.linking = false;
    vn.contextScreenX = gui::clampf(mx - vn.canvasRect.x, 8.0, gui::maxf(16.0, vn.canvasRect.w - 220.0));
    vn.contextScreenY = gui::clampf(my - vn.canvasRect.y, 8.0, gui::maxf(16.0, vn.canvasRect.h - 230.0));
    vn.contextWorldX = screenToWorldX(&vn, mx);
    vn.contextWorldY = screenToWorldY(&vn, my);

    PortHit ph = hitTestPort(&vn, mx, my);
    if (ph.found) {
      vn.selectedNode = ph.nodeIdx;
      vn.selectedWire = -1;
      vn.contextKind = ContextKind::CtxPort as int;
      vn.contextNode = ph.nodeIdx;
      vn.contextPort = ph.portIdx;
      vn.contextPortIsOut = ph.isOutput;
      return;
    }

    int nh = hitTestNodeCard(&vn, vn.contextWorldX, vn.contextWorldY);
    if (nh >= 0) {
      vn.selectedNode = nh;
      vn.selectedWire = -1;
      vn.contextKind = ContextKind::CtxNode as int;
      vn.contextNode = nh;
      return;
    }

    int wh = hitTestWire(&vn, mx, my);
    if (wh >= 0) {
      vn.selectedWire = wh;
      vn.selectedNode = -1;
      vn.contextKind = ContextKind::CtxWire as int;
      vn.contextWire = wh;
      return;
    }

    vn.contextKind = ContextKind::CtxCanvas as int;
    return;
  }

  // Middle click / pan start anywhere in canvas
  if (gui::middleClicked() && inCanvas && !overPopup) {
    dismissPopups(&vn);
    vn.panning = true;
    vn.panStartX = vn.panX;
    vn.panStartY = vn.panY;
    vn.dragStartMouseX = mx;
    vn.dragStartMouseY = my;
    return;
  }

  // Left mouse press on canvas
  if (gui::mouseClicked() && inCanvas && !overPopup) {
    if (gui::keyDown(GuiKey::GuiKeySpace)) {
      vn.panning = true;
      vn.panStartX = vn.panX;
      vn.panStartY = vn.panY;
      vn.dragStartMouseX = mx;
      vn.dragStartMouseY = my;
      return;
    }

    PortHit ph = hitTestPort(&vn, mx, my);
    if (ph.found) {
      vn.linking = true;
      vn.linkStartNode = ph.nodeIdx;
      vn.linkStartPort = ph.portIdx;
      vn.linkFromOutput = ph.isOutput;
      vn.linkPinType = if (ph.isOutput)
        vn.nodes[ph.nodeIdx].outputs[ph.portIdx].pinType
      else
        vn.nodes[ph.nodeIdx].inputs[ph.portIdx].pinType;
      vn.linkCurX = mx;
      vn.linkCurY = my;
      vn.selectedNode = ph.nodeIdx;
      vn.selectedWire = -1;
      return;
    }

    float wx = screenToWorldX(&vn, mx);
    float wy = screenToWorldY(&vn, my);
    int nh = hitTestNodeCard(&vn, wx, wy);
    if (nh >= 0) {
      int front = bringNodeToFront(&vn, nh);
      vn.selectedNode = front;
      vn.selectedWire = -1;
      vn.draggingNode = true;
      vn.dragStartNodeX = vn.nodes[front].x;
      vn.dragStartNodeY = vn.nodes[front].y;
      vn.dragStartMouseX = mx;
      vn.dragStartMouseY = my;
      return;
    }

    int wh = hitTestWire(&vn, mx, my);
    if (wh >= 0) {
      vn.selectedWire = wh;
      vn.selectedNode = -1;
      return;
    }

    // Empty canvas drag pans smoothly
    vn.selectedNode = -1;
    vn.selectedWire = -1;
    vn.panning = true;
    vn.panStartX = vn.panX;
    vn.panStartY = vn.panY;
    vn.dragStartMouseX = mx;
    vn.dragStartMouseY = my;
  }

  // Active wire connection drag & release snap
  if (vn.linking) {
    if (gui::mouseDown()) {
      vn.linkCurX = mx;
      vn.linkCurY = my;
    } else {
      vn.linking = false;
      PortHit target = hitTestPort(&vn, mx, my);
      if (target.found && target.nodeIdx != vn.linkStartNode && target.isOutput != vn.linkFromOutput) {
        if (vn.linkFromOutput) {
          connectPorts(&vn, vn.linkStartNode, vn.linkStartPort, target.nodeIdx, target.portIdx);
        } else {
          connectPorts(&vn, target.nodeIdx, target.portIdx, vn.linkStartNode, vn.linkStartPort);
        }
      }
    }
  }

  // Active node card dragging
  if (vn.draggingNode) {
    if (gui::mouseDown() && vn.selectedNode >= 0 && vn.selectedNode < vn.nodeCount) {
      float dx = (mx - vn.dragStartMouseX) / vn.zoom;
      float dy = (my - vn.dragStartMouseY) / vn.zoom;
      vn.nodes[vn.selectedNode].x = snapWorld(vn.dragStartNodeX + dx, vn.snapToGrid);
      vn.nodes[vn.selectedNode].y = snapWorld(vn.dragStartNodeY + dy, vn.snapToGrid);
    } else {
      vn.draggingNode = false;
    }
  }

  // Active canvas panning
  if (vn.panning) {
    if (gui::mouseDown() || gui::middleDown()) {
      vn.panX = vn.panStartX + (mx - vn.dragStartMouseX);
      vn.panY = vn.panStartY + (my - vn.dragStartMouseY);
    } else {
      vn.panning = false;
    }
  }
}
