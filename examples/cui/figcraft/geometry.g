// FigCraft Geometry, Coordinate Transforms, Hit Testing, and Alignment Math.
// Pure functions with zero CUI side effects for straightforward unit testing.

import std.gui;
import std.cui;
import std.string;
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

int findNodeIndexById(Editor* e, int id) {
  if (id < 0) { return -1; }
  for (int i = 0; i < e.count; i = i + 1) {
    if (e.nodes[i].id == id) { return i; }
  }
  return -1;
}

bool isNodeContainerKind(int kind) {
  return kind == (NodeKind::NodeFrame as int) ||
         kind == (NodeKind::NodeSection as int);
}

bool isNodeDescendant(Editor* e, int candidateIdx, int ancestorId) {
  if (candidateIdx < 0 || candidateIdx >= e.count || ancestorId < 0) { return false; }
  int pid = e.nodes[candidateIdx].parentId;
  int hops = 0;
  while (pid >= 0 && hops < e.count) {
    if (pid == ancestorId) { return true; }
    int pIdx = findNodeIndexById(e, pid);
    if (pIdx < 0) { return false; }
    pid = e.nodes[pIdx].parentId;
    hops = hops + 1;
  }
  return false;
}

bool isNodeVisibleInHierarchy(Editor* e, int idx) {
  if (idx < 0 || idx >= e.count) { return false; }
  if (!e.nodes[idx].visible) { return false; }
  int pid = e.nodes[idx].parentId;
  int hops = 0;
  while (pid >= 0 && hops < e.count) {
    int pIdx = findNodeIndexById(e, pid);
    if (pIdx < 0) { break; }
    if (!e.nodes[pIdx].visible) { return false; }
    pid = e.nodes[pIdx].parentId;
    hops = hops + 1;
  }
  return true;
}

bool pointInsideClippedAncestors(Editor* e, int idx, float dx, float dy) {
  if (idx < 0 || idx >= e.count) { return false; }
  int pid = e.nodes[idx].parentId;
  int hops = 0;
  while (pid >= 0 && hops < e.count) {
    int pIdx = findNodeIndexById(e, pid);
    if (pIdx < 0) { break; }
    if (e.nodes[pIdx].clipContent) {
      if (dx < e.nodes[pIdx].x || dx > e.nodes[pIdx].x + e.nodes[pIdx].w ||
          dy < e.nodes[pIdx].y || dy > e.nodes[pIdx].y + e.nodes[pIdx].h) {
        return false;
      }
    }
    pid = e.nodes[pIdx].parentId;
    hops = hops + 1;
  }
  return true;
}

bool nodeHasChildren(Editor* e, int idx) {
  if (idx < 0 || idx >= e.count) { return false; }
  int nid = e.nodes[idx].id;
  for (int i = 0; i < e.count; i = i + 1) {
    if (i != idx && e.nodes[i].parentId == nid) { return true; }
  }
  return false;
}

int hitTestNode(Editor* e, float dx, float dy) {
  for (int i = e.count - 1; i >= 0; i = i - 1) {
    if (!isNodeVisibleInHierarchy(e, i)) { continue; }
    if (!pointInsideClippedAncestors(e, i, dx, dy)) { continue; }
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

float absf(float v) {
  if (v < 0.0) { return -v; }
  return v;
}

void clearSnapGuides(Editor* e) {
  if (e == nullptr) { return; }
  e.snapCountX = 0;
  e.snapCountY = 0;
  e.snapCenterCenter = false;
  e.snapCenterX = 0.0;
  e.snapCenterY = 0.0;
  e.snapBadgeText[0] = '\0';
}

void recordSnapGuideX(Editor* e, float x, float y0, float y1, int kind) {
  float minY = gui::minf(y0, y1);
  float maxY = gui::maxf(y0, y1);
  for (int i = 0; i < e.snapCountX; i = i + 1) {
    if (absf(e.snapLineX[i] - x) < 0.5) {
      e.snapLineY0[i] = gui::minf(e.snapLineY0[i], minY);
      e.snapLineY1[i] = gui::maxf(e.snapLineY1[i], maxY);
      if (kind == 1) { e.snapKindX[i] = 1; }
      return;
    }
  }
  if (e.snapCountX < 4) {
    int k = e.snapCountX;
    e.snapLineX[k] = x;
    e.snapLineY0[k] = minY;
    e.snapLineY1[k] = maxY;
    e.snapKindX[k] = kind;
    e.snapCountX = k + 1;
  }
}

void recordSnapGuideY(Editor* e, float y, float x0, float x1, int kind) {
  float minX = gui::minf(x0, x1);
  float maxX = gui::maxf(x0, x1);
  for (int i = 0; i < e.snapCountY; i = i + 1) {
    if (absf(e.snapLineY[i] - y) < 0.5) {
      e.snapLineX0[i] = gui::minf(e.snapLineX0[i], minX);
      e.snapLineX1[i] = gui::maxf(e.snapLineX1[i], maxX);
      if (kind == 1) { e.snapKindY[i] = 1; }
      return;
    }
  }
  if (e.snapCountY < 4) {
    int k = e.snapCountY;
    e.snapLineY[k] = y;
    e.snapLineX0[k] = minX;
    e.snapLineX1[k] = maxX;
    e.snapKindY[k] = kind;
    e.snapCountY = k + 1;
  }
}

Rect computeSmartSnapMove(Editor* e, int nodeIdx, float rawX, float rawY, float tol) {
  clearSnapGuides(e);
  if (e == nullptr || nodeIdx < 0 || nodeIdx >= e.count) {
    return Rect{x: rawX, y: rawY, w: 0.0, h: 0.0};
  }
  float nw = e.nodes[nodeIdx].w;
  float nh = e.nodes[nodeIdx].h;
  if (!e.snapEnabled) {
    return Rect{x: rawX, y: rawY, w: nw, h: nh};
  }

  float[3] dragX;
  dragX[0] = rawX;
  dragX[1] = rawX + nw * 0.5;
  dragX[2] = rawX + nw;

  float[3] dragY;
  dragY[0] = rawY;
  dragY[1] = rawY + nh * 0.5;
  dragY[2] = rawY + nh;

  float bestDx = 0.0;
  float bestScoreX = tol + 1.0;
  bool foundX = false;

  float bestDy = 0.0;
  float bestScoreY = tol + 1.0;
  bool foundY = false;

  // Stage Root candidate edges + center
  float[3] stgX;
  stgX[0] = 0.0;
  stgX[1] = e.stageW * 0.5;
  stgX[2] = e.stageW;
  for (int a = 0; a < 3; a = a + 1) {
    for (int t = 0; t < 3; t = t + 1) {
      float diff = stgX[t] - dragX[a];
      float d = absf(diff);
      if (d <= tol) {
        float score = if (a == 1 && t == 1) d - 0.15 else d;
        if (score < bestScoreX) {
          bestScoreX = score;
          bestDx = diff;
          foundX = true;
        }
      }
    }
  }

  float[3] stgY;
  stgY[0] = 0.0;
  stgY[1] = e.stageH * 0.5;
  stgY[2] = e.stageH;
  for (int a = 0; a < 3; a = a + 1) {
    for (int t = 0; t < 3; t = t + 1) {
      float diff = stgY[t] - dragY[a];
      float d = absf(diff);
      if (d <= tol) {
        float score = if (a == 1 && t == 1) d - 0.15 else d;
        if (score < bestScoreY) {
          bestScoreY = score;
          bestDy = diff;
          foundY = true;
        }
      }
    }
  }

  // Other visible components (skip self and descendants of self)
  int dragId = e.nodes[nodeIdx].id;
  for (int j = 0; j < e.count; j = j + 1) {
    if (j == nodeIdx) { continue; }
    if (!isNodeVisibleInHierarchy(e, j)) { continue; }
    if (isNodeDescendant(e, j, dragId)) { continue; }
    DesignNode* o = &e.nodes[j];
    float[3] ox;
    ox[0] = o.x;
    ox[1] = o.x + o.w * 0.5;
    ox[2] = o.x + o.w;
    for (int a = 0; a < 3; a = a + 1) {
      for (int t = 0; t < 3; t = t + 1) {
        float diff = ox[t] - dragX[a];
        float d = absf(diff);
        if (d <= tol) {
          float score = if (a == 1 && t == 1) d - 0.15 else d;
          if (score < bestScoreX) {
            bestScoreX = score;
            bestDx = diff;
            foundX = true;
          }
        }
      }
    }

    float[3] oy;
    oy[0] = o.y;
    oy[1] = o.y + o.h * 0.5;
    oy[2] = o.y + o.h;
    for (int a = 0; a < 3; a = a + 1) {
      for (int t = 0; t < 3; t = t + 1) {
        float diff = oy[t] - dragY[a];
        float d = absf(diff);
        if (d <= tol) {
          float score = if (a == 1 && t == 1) d - 0.15 else d;
          if (score < bestScoreY) {
            bestScoreY = score;
            bestDy = diff;
            foundY = true;
          }
        }
      }
    }
  }

  float sx = if (foundX) rawX + bestDx else rawX;
  float sy = if (foundY) rawY + bestDy else rawY;

  float[3] finalX;
  finalX[0] = sx;
  finalX[1] = sx + nw * 0.5;
  finalX[2] = sx + nw;
  float[3] finalY;
  finalY[0] = sy;
  finalY[1] = sy + nh * 0.5;
  finalY[2] = sy + nh;

  float eps = 0.5;
  bool stageCenterMatchX = false;
  bool stageCenterMatchY = false;

  // Record Stage Root matches
  for (int a = 0; a < 3; a = a + 1) {
    for (int t = 0; t < 3; t = t + 1) {
      if (absf(finalX[a] - stgX[t]) <= eps) {
        int kind = if (a == 1 || t == 1) 1 else 0;
        recordSnapGuideX(e, stgX[t], gui::minf(sy, 0.0), gui::maxf(sy + nh, e.stageH), kind);
        if (a == 1 && t == 1) { stageCenterMatchX = true; }
      }
      if (absf(finalY[a] - stgY[t]) <= eps) {
        int kind = if (a == 1 || t == 1) 1 else 0;
        recordSnapGuideY(e, stgY[t], gui::minf(sx, 0.0), gui::maxf(sx + nw, e.stageW), kind);
        if (a == 1 && t == 1) { stageCenterMatchY = true; }
      }
    }
  }

  if (stageCenterMatchX && stageCenterMatchY) {
    e.snapCenterCenter = true;
    e.snapCenterX = finalX[1];
    e.snapCenterY = finalY[1];
    std::string::copy(&e.snapBadgeText[0], "Stage Center", 32);
  }

  // Record Component matches (including Component Center-Center)
  bool hasAnyCenterX = stageCenterMatchX;
  bool hasAnyCenterY = stageCenterMatchY;
  for (int j = 0; j < e.count; j = j + 1) {
    if (j == nodeIdx) { continue; }
    if (!isNodeVisibleInHierarchy(e, j)) { continue; }
    if (isNodeDescendant(e, j, dragId)) { continue; }
    DesignNode* o = &e.nodes[j];
    float[3] ox;
    ox[0] = o.x;
    ox[1] = o.x + o.w * 0.5;
    ox[2] = o.x + o.w;
    float[3] oy;
    oy[0] = o.y;
    oy[1] = o.y + o.h * 0.5;
    oy[2] = o.y + o.h;

    bool compCenterX = false;
    bool compCenterY = false;

    for (int a = 0; a < 3; a = a + 1) {
      for (int t = 0; t < 3; t = t + 1) {
        if (absf(finalX[a] - ox[t]) <= eps) {
          int kind = if (a == 1 || t == 1) 1 else 0;
          recordSnapGuideX(e, ox[t], gui::minf(sy, o.y), gui::maxf(sy + nh, o.y + o.h), kind);
          if (a == 1 && t == 1) { compCenterX = true; hasAnyCenterX = true; }
        }
        if (absf(finalY[a] - oy[t]) <= eps) {
          int kind = if (a == 1 || t == 1) 1 else 0;
          recordSnapGuideY(e, oy[t], gui::minf(sx, o.x), gui::maxf(sx + nw, o.x + o.w), kind);
          if (a == 1 && t == 1) { compCenterY = true; hasAnyCenterY = true; }
        }
      }
    }

    if (compCenterX && compCenterY) {
      e.snapCenterCenter = true;
      e.snapCenterX = finalX[1];
      e.snapCenterY = finalY[1];
      std::string::copy(&e.snapBadgeText[0], "Center \xc2\xb7 Center", 32);
    }
  }

  if (!e.snapCenterCenter && hasAnyCenterX && hasAnyCenterY) {
    e.snapCenterCenter = true;
    e.snapCenterX = finalX[1];
    e.snapCenterY = finalY[1];
    std::string::copy(&e.snapBadgeText[0], "Center \xc2\xb7 Center", 32);
  }

  return Rect{x: sx, y: sy, w: nw, h: nh};
}

Rect computeSmartSnapResize(Editor* e, int nodeIdx, int handle, Rect rawRect, float minSize, float tol) {
  clearSnapGuides(e);
  if (e == nullptr || nodeIdx < 0 || nodeIdx >= e.count || !e.snapEnabled) {
    return rawRect;
  }

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

  float rx = rawRect.x;
  float ry = rawRect.y;
  float rw = rawRect.w;
  float rh = rawRect.h;

  float edgeL = rx;
  float edgeR = rx + rw;
  float edgeT = ry;
  float edgeB = ry + rh;

  float bestL = 0.0; float bestDistL = tol + 1.0; bool snapL = false;
  float bestR = 0.0; float bestDistR = tol + 1.0; bool snapR = false;
  float bestT = 0.0; float bestDistT = tol + 1.0; bool snapT = false;
  float bestB = 0.0; float bestDistB = tol + 1.0; bool snapB = false;

  int dragId = e.nodes[nodeIdx].id;

  // Stage targets
  float[3] stgX;
  stgX[0] = 0.0; stgX[1] = e.stageW * 0.5; stgX[2] = e.stageW;
  for (int t = 0; t < 3; t = t + 1) {
    if (hasL && absf(stgX[t] - edgeL) <= tol && absf(stgX[t] - edgeL) < bestDistL) {
      if (edgeR - stgX[t] >= minSize) {
        bestDistL = absf(stgX[t] - edgeL); bestL = stgX[t]; snapL = true;
      }
    }
    if (hasR && absf(stgX[t] - edgeR) <= tol && absf(stgX[t] - edgeR) < bestDistR) {
      if (stgX[t] - edgeL >= minSize) {
        bestDistR = absf(stgX[t] - edgeR); bestR = stgX[t]; snapR = true;
      }
    }
  }

  float[3] stgY;
  stgY[0] = 0.0; stgY[1] = e.stageH * 0.5; stgY[2] = e.stageH;
  for (int t = 0; t < 3; t = t + 1) {
    if (hasT && absf(stgY[t] - edgeT) <= tol && absf(stgY[t] - edgeT) < bestDistT) {
      if (edgeB - stgY[t] >= minSize) {
        bestDistT = absf(stgY[t] - edgeT); bestT = stgY[t]; snapT = true;
      }
    }
    if (hasB && absf(stgY[t] - edgeB) <= tol && absf(stgY[t] - edgeB) < bestDistB) {
      if (stgY[t] - edgeT >= minSize) {
        bestDistB = absf(stgY[t] - edgeB); bestB = stgY[t]; snapB = true;
      }
    }
  }

  for (int j = 0; j < e.count; j = j + 1) {
    if (j == nodeIdx || !isNodeVisibleInHierarchy(e, j) || isNodeDescendant(e, j, dragId)) { continue; }
    DesignNode* o = &e.nodes[j];
    float[3] ox; ox[0] = o.x; ox[1] = o.x + o.w * 0.5; ox[2] = o.x + o.w;
    for (int t = 0; t < 3; t = t + 1) {
      if (hasL && absf(ox[t] - edgeL) <= tol && absf(ox[t] - edgeL) < bestDistL && edgeR - ox[t] >= minSize) {
        bestDistL = absf(ox[t] - edgeL); bestL = ox[t]; snapL = true;
      }
      if (hasR && absf(ox[t] - edgeR) <= tol && absf(ox[t] - edgeR) < bestDistR && ox[t] - edgeL >= minSize) {
        bestDistR = absf(ox[t] - edgeR); bestR = ox[t]; snapR = true;
      }
    }
    float[3] oy; oy[0] = o.y; oy[1] = o.y + o.h * 0.5; oy[2] = o.y + o.h;
    for (int t = 0; t < 3; t = t + 1) {
      if (hasT && absf(oy[t] - edgeT) <= tol && absf(oy[t] - edgeT) < bestDistT && edgeB - oy[t] >= minSize) {
        bestDistT = absf(oy[t] - edgeT); bestT = oy[t]; snapT = true;
      }
      if (hasB && absf(oy[t] - edgeB) <= tol && absf(oy[t] - edgeB) < bestDistB && oy[t] - edgeT >= minSize) {
        bestDistB = absf(oy[t] - edgeB); bestB = oy[t]; snapB = true;
      }
    }
  }

  if (snapL) {
    float newR = rx + rw;
    rx = bestL;
    rw = newR - bestL;
    recordSnapGuideX(e, bestL, ry, ry + rh, 0);
  }
  if (snapR) {
    rw = bestR - rx;
    recordSnapGuideX(e, bestR, ry, ry + rh, 0);
  }
  if (snapT) {
    float newB = ry + rh;
    ry = bestT;
    rh = newB - bestT;
    recordSnapGuideY(e, bestT, rx, rx + rw, 0);
  }
  if (snapB) {
    rh = bestB - ry;
    recordSnapGuideY(e, bestB, rx, rx + rw, 0);
  }

  return Rect{x: rx, y: ry, w: rw, h: rh};
}

const char* nodeGlyph(int kind) {
  if (kind == (NodeKind::NodeText as int)) { return std::cui::icons::textTool(); }
  if (kind == (NodeKind::NodeChart as int)) { return std::cui::icons::chartBar(); }
  if (kind == (NodeKind::NodeLine as int)) { return std::cui::icons::minus(); }
  if (kind == (NodeKind::NodeSparkline as int)) { return std::cui::icons::activity(); }
  if (kind == (NodeKind::NodeDonut as int)) { return std::cui::icons::chartLine(); }
  if (kind == (NodeKind::NodeButton as int)) { return std::cui::icons::tag(); }
  if (kind == (NodeKind::NodePen as int)) { return std::cui::icons::pencil(); }
  if (kind == (NodeKind::NodePencil as int)) { return std::cui::icons::activity(); }
  if (kind == (NodeKind::NodeComment as int)) { return std::cui::icons::message(); }
  if (kind == (NodeKind::NodeFrame as int)) { return std::cui::icons::grid(); }
  if (kind == (NodeKind::NodeSection as int)) { return std::cui::icons::box(); }
  if (kind == (NodeKind::NodeSlice as int)) { return std::cui::icons::target(); }
  if (kind == (NodeKind::NodeEllipse as int)) { return std::cui::icons::circle(); }
  if (kind == (NodeKind::NodeArrow as int)) { return std::cui::icons::arrowRight(); }
  if (kind == (NodeKind::NodePolygon as int)) { return std::cui::icons::layers(); }
  if (kind == (NodeKind::NodeStar as int)) { return std::cui::icons::star(); }
  if (kind == (NodeKind::NodeImage as int)) { return std::cui::icons::sparkles(); }
  return std::cui::icons::square();
}

bool nodeHasTypography(int kind) {
  return kind == (NodeKind::NodeText as int) ||
         kind == (NodeKind::NodeButton as int) ||
         kind == (NodeKind::NodeComment as int);
}

bool nodeIsLineOrArrow(int kind) {
  return kind == (NodeKind::NodeLine as int) ||
         kind == (NodeKind::NodeArrow as int);
}

bool nodeIsPolyOrStar(int kind) {
  return kind == (NodeKind::NodePolygon as int) ||
         kind == (NodeKind::NodeStar as int);
}

bool nodeIsChart(int kind) {
  return kind == (NodeKind::NodeChart as int) ||
         kind == (NodeKind::NodeSparkline as int) ||
         kind == (NodeKind::NodeDonut as int);
}

const char* nodeKindLabel(int kind) {
  if (kind == (NodeKind::NodeText as int)) { return "Text"; }
  if (kind == (NodeKind::NodeChart as int)) { return "Bar Chart"; }
  if (kind == (NodeKind::NodeLine as int)) { return "Line"; }
  if (kind == (NodeKind::NodeSparkline as int)) { return "Sparkline"; }
  if (kind == (NodeKind::NodeDonut as int)) { return "Donut Chart"; }
  if (kind == (NodeKind::NodeButton as int)) { return "Button / Pill"; }
  if (kind == (NodeKind::NodePen as int)) { return "Vector"; }
  if (kind == (NodeKind::NodePencil as int)) { return "Pencil"; }
  if (kind == (NodeKind::NodeComment as int)) { return "Comment"; }
  if (kind == (NodeKind::NodeFrame as int)) { return "Frame"; }
  if (kind == (NodeKind::NodeSection as int)) { return "Section"; }
  if (kind == (NodeKind::NodeSlice as int)) { return "Slice"; }
  if (kind == (NodeKind::NodeEllipse as int)) { return "Ellipse"; }
  if (kind == (NodeKind::NodeArrow as int)) { return "Arrow"; }
  if (kind == (NodeKind::NodePolygon as int)) { return "Polygon"; }
  if (kind == (NodeKind::NodeStar as int)) { return "Star"; }
  if (kind == (NodeKind::NodeImage as int)) { return "Image"; }
  return "Rectangle";
}

const char* sectionLabelOf(int kind) {
  if (kind == 0) { return "Navbar"; }
  if (kind == 1) { return "Hero Banner"; }
  if (kind == 2) { return "3-Col Cards"; }
  if (kind == 3) { return "Login Card"; }
  if (kind == 4) { return "KPI Stat"; }
  return "Footer Bar";
}

const char* assetLabelOf(int kind) {
  if (kind == 0) { return "Button"; }
  if (kind == 1) { return "Outline Btn"; }
  if (kind == 2) { return "Card"; }
  if (kind == 3) { return "Input Field"; }
  if (kind == 4) { return "Status Badge"; }
  if (kind == 5) { return "Bar Chart"; }
  if (kind == 6) { return "Sparkline"; }
  if (kind == 7) { return "Donut Ring"; }
  if (kind == 8) { return "Avatar"; }
  if (kind == 9) { return "Toggle"; }
  if (kind == 10) { return "Image Frame"; }
  return "Comment Pin";
}

Rect computeDropFootprint(Editor* e, bool isSection, int kind, float dropCx, float dropCy) {
  float w = 160.0;
  float h = 42.0;
  if (isSection) {
    if (kind == 0) { w = 1120.0; h = 68.0; }
    else if (kind == 1) { w = 1120.0; h = 320.0; }
    else if (kind == 2) { w = 1120.0; h = 210.0; }
    else if (kind == 3) { w = 380.0; h = 360.0; }
    else if (kind == 4) { w = 440.0; h = 240.0; }
    else { w = 1120.0; h = 92.0; }
  } else {
    if (kind == 0) { w = 160.0; h = 42.0; }
    else if (kind == 1) { w = 160.0; h = 42.0; }
    else if (kind == 2) { w = 260.0; h = 148.0; }
    else if (kind == 3) { w = 240.0; h = 60.0; }
    else if (kind == 4) { w = 108.0; h = 26.0; }
    else if (kind == 5) { w = 300.0; h = 150.0; }
    else if (kind == 6) { w = 220.0; h = 76.0; }
    else if (kind == 7) { w = 128.0; h = 128.0; }
    else if (kind == 8) { w = 48.0; h = 48.0; }
    else if (kind == 9) { w = 52.0; h = 28.0; }
    else if (kind == 10) { w = 240.0; h = 150.0; }
    else { w = 148.0; h = 30.0; }
  }
  return Rect{x: dropCx - w * 0.5, y: dropCy - h * 0.5, w: w, h: h};
}

void refreshInspectorLabels(Editor* e) {
  formatPercent(&e.zoomLabel[0], effectiveScale(e), 16);
  std::string::format_int(&e.layerCountLabel[0], e.count, 16);

  if (e.selected >= 0 && e.selected < e.count) {
    DesignNode* n = &e.nodes[e.selected];
    formatDims(&e.dimLabel[0], (n.w + 0.5) as int, (n.h + 0.5) as int, 32);
    Color fc = if (n.fill.a > 0) n.fill else n.ink;
    formatHexColor(&e.hexLabel[0], fc, 16);
    formatHexColor(&e.strokeHexLabel[0], n.stroke, 16);
    formatHexColor(&e.inkHexLabel[0], n.ink, 16);
    formatHexColor(&e.dropHexLabel[0], n.dropShadowColor, 16);
    formatHexColor(&e.innerHexLabel[0], n.innerShadowColor, 16);
    formatHexColor(&e.bgBlurHexLabel[0], n.bgBlurColor, 16);
    formatPercent(&e.dropAlphaLabel[0], (n.dropShadowColor.a as float) / 255.0, 16);
    formatPercent(&e.innerAlphaLabel[0], (n.innerShadowColor.a as float) / 255.0, 16);
    formatPercent(&e.bgBlurAlphaLabel[0], (n.bgBlurColor.a as float) / 255.0, 16);
    formatDegree(&e.degLabel[0], n.rotation, 24);
    formatPercent(&e.opacityLabel[0], n.opacity, 24);
  } else {
    formatDims(&e.dimLabel[0], (e.stageW + 0.5) as int, (e.stageH + 0.5) as int, 32);
    formatHexColor(&e.hexLabel[0], e.stageBg, 16);
    formatHexColor(&e.strokeHexLabel[0], fcDesignBorder(), 16);
    formatHexColor(&e.inkHexLabel[0], fcNavy(), 16);
    formatHexColor(&e.dropHexLabel[0], gui::rgba(0, 0, 0, 22), 16);
    formatHexColor(&e.innerHexLabel[0], gui::rgba(0, 0, 0, 0), 16);
    formatHexColor(&e.bgBlurHexLabel[0], gui::rgba(255, 255, 255, 168), 16);
    std::string::copy(&e.dropAlphaLabel[0], "9%", 16);
    std::string::copy(&e.innerAlphaLabel[0], "0%", 16);
    std::string::copy(&e.bgBlurAlphaLabel[0], "66%", 16);
    formatDegree(&e.degLabel[0], 0.0, 24);
    formatPercent(&e.opacityLabel[0], e.stageOpacity, 24);
  }
}
