// VisualNob Geometry, Port Positioning, Bezier Wire Hit-Testing, and Grid Snapping.
// Pure functions cleanly decoupled from rendering and UI handlers.

import std.gui;
import examples.cui.visualnob.palette;
import examples.cui.visualnob.model;

struct Vec2 {
  float x;
  float y;
}

struct PortHit {
  bool found;
  int nodeIdx;
  int portIdx;
  bool isOutput;
}

float nodeHeaderH() => 28.0;
float portRowH() => 22.0;
float nodeBodyTopPad() => 8.0;
float nodeFooterPad() => 10.0;

float worldToScreenX(GraphEditor* e, float wx) {
  return e.canvasRect.x + e.panX + wx * e.zoom;
}

float worldToScreenY(GraphEditor* e, float wy) {
  return e.canvasRect.y + e.panY + wy * e.zoom;
}

float screenToWorldX(GraphEditor* e, float sx) {
  if (e.zoom <= 0.001) { return 0.0; }
  return (sx - e.canvasRect.x - e.panX) / e.zoom;
}

float screenToWorldY(GraphEditor* e, float sy) {
  if (e.zoom <= 0.001) { return 0.0; }
  return (sy - e.canvasRect.y - e.panY) / e.zoom;
}

float snapWorld(float v, bool enabled) {
  if (!enabled) { return v; }
  float grid = 16.0;
  float shifted = if (v >= 0.0) v + grid * 0.5 else v - grid * 0.5;
  int cell = (shifted / grid) as int;
  return (cell as float) * grid;
}

float computeNodeHeight(ScriptNode* n) {
  if (n.kind == (VnNodeKind::VnComment as int)) {
    return 86.0;
  }
  if (n.collapsed) {
    return nodeHeaderH() + 6.0;
  }
  int rows = if (n.inputCount > n.outputCount) n.inputCount else n.outputCount;
  if (rows < 1) { rows = 1; }
  bool hasSummary =
    n.kind == (VnNodeKind::VnConstNumber as int) ||
    n.kind == (VnNodeKind::VnConstString as int) ||
    n.kind == (VnNodeKind::VnConstBool as int) ||
    n.kind == (VnNodeKind::VnGetVar as int) ||
    n.kind == (VnNodeKind::VnSetVar as int) ||
    n.kind == (VnNodeKind::VnCompare as int) ||
    n.kind == (VnNodeKind::VnMathAdd as int) ||
    n.kind == (VnNodeKind::VnMathMul as int);
  float extra = if (hasSummary) 22.0 else 0.0;
  return nodeHeaderH() + nodeBodyTopPad() + (rows as float) * portRowH() + extra + nodeFooterPad();
}

Vec2 inputPortWorldPos(ScriptNode* n, int portIdx) {
  float py = n.y + nodeHeaderH() + nodeBodyTopPad() + (portIdx as float) * portRowH() + portRowH() * 0.5;
  return Vec2{x: n.x, y: py};
}

Vec2 outputPortWorldPos(ScriptNode* n, int portIdx) {
  float py = n.y + nodeHeaderH() + nodeBodyTopPad() + (portIdx as float) * portRowH() + portRowH() * 0.5;
  return Vec2{x: n.x + n.w, y: py};
}

Vec2 inputPortScreenPos(GraphEditor* e, int nodeIdx, int portIdx) {
  Vec2 wp = inputPortWorldPos(&e.nodes[nodeIdx], portIdx);
  return Vec2{
    x: worldToScreenX(e, wp.x),
    y: worldToScreenY(e, wp.y)
  };
}

Vec2 outputPortScreenPos(GraphEditor* e, int nodeIdx, int portIdx) {
  Vec2 wp = outputPortWorldPos(&e.nodes[nodeIdx], portIdx);
  return Vec2{
    x: worldToScreenX(e, wp.x),
    y: worldToScreenY(e, wp.y)
  };
}

PortHit hitTestPort(GraphEditor* e, float sx, float sy) {
  float hitR = gui::maxf(10.0, 11.0 * e.zoom);
  float hitR2 = hitR * hitR;

  for (int i = e.nodeCount - 1; i >= 0; i = i - 1) {
    ScriptNode* n = &e.nodes[i];
    if (n.collapsed) { continue; }
    for (int p = 0; p < n.outputCount; p = p + 1) {
      Vec2 pt = outputPortScreenPos(e, i, p);
      float dx = sx - pt.x;
      float dy = sy - pt.y;
      if (dx * dx + dy * dy <= hitR2) {
        return PortHit{found: true, nodeIdx: i, portIdx: p, isOutput: true};
      }
    }
    for (int p = 0; p < n.inputCount; p = p + 1) {
      Vec2 pt = inputPortScreenPos(e, i, p);
      float dx = sx - pt.x;
      float dy = sy - pt.y;
      if (dx * dx + dy * dy <= hitR2) {
        return PortHit{found: true, nodeIdx: i, portIdx: p, isOutput: false};
      }
    }
  }
  return PortHit{found: false, nodeIdx: -1, portIdx: -1, isOutput: false};
}

int hitTestNodeCard(GraphEditor* e, float wx, float wy) {
  for (int i = e.nodeCount - 1; i >= 0; i = i - 1) {
    ScriptNode* n = &e.nodes[i];
    float h = computeNodeHeight(n);
    if (wx >= n.x && wx <= n.x + n.w && wy >= n.y && wy <= n.y + h) {
      return i;
    }
  }
  return -1;
}

float pointSegmentDistSq(float px, float py, float ax, float ay, float bx, float by) {
  float vx = bx - ax;
  float vy = by - ay;
  float len2 = vx * vx + vy * vy;
  if (len2 <= 0.0001) {
    float dx = px - ax;
    float dy = py - ay;
    return dx * dx + dy * dy;
  }
  float t = ((px - ax) * vx + (py - ay) * vy) / len2;
  t = gui::clampf(t, 0.0, 1.0);
  float cx = ax + t * vx;
  float cy = ay + t * vy;
  float dx = px - cx;
  float dy = py - cy;
  return dx * dx + dy * dy;
}

float distanceToWireScreenSq(GraphEditor* e, int wireIdx, float sx, float sy) {
  if (wireIdx < 0 || wireIdx >= e.wireCount) { return 1000000.0; }
  Wire* w = &e.wires[wireIdx];
  Vec2 p0 = outputPortScreenPos(e, w.fromNode, w.fromPort);
  Vec2 p1 = inputPortScreenPos(e, w.toNode, w.toPort);

  float dx = gui::absf(p1.x - p0.x);
  float dy = gui::absf(p1.y - p0.y);
  float handle = gui::maxf(48.0, dx * 0.48);
  if (p1.x < p0.x) {
    handle = gui::maxf(72.0, gui::minf(180.0, dx * 0.55 + dy * 0.25));
  }
  float c0x = p0.x + handle;
  float c0y = p0.y;
  float c1x = p1.x - handle;
  float c1y = p1.y;

  float best = 1000000.0;
  float prevX = p0.x;
  float prevY = p0.y;
  int segs = 18;
  for (int s = 1; s <= segs; s = s + 1) {
    float t = (s as float) / (segs as float);
    float qx = gui::bezierEval(p0.x, c0x, c1x, p1.x, t);
    float qy = gui::bezierEval(p0.y, c0y, c1y, p1.y, t);
    float d2 = pointSegmentDistSq(sx, sy, prevX, prevY, qx, qy);
    if (d2 < best) { best = d2; }
    prevX = qx;
    prevY = qy;
  }
  return best;
}

int hitTestWire(GraphEditor* e, float sx, float sy) {
  float best = 81.0; // 9px radius
  int hit = -1;
  for (int i = e.wireCount - 1; i >= 0; i = i - 1) {
    float d2 = distanceToWireScreenSq(e, i, sx, sy);
    if (d2 < best) {
      best = d2;
      hit = i;
    }
  }
  return hit;
}

bool inputPortHasWire(GraphEditor* e, int nodeIdx, int portIdx) {
  for (int i = 0; i < e.wireCount; i = i + 1) {
    if (e.wires[i].toNode == nodeIdx && e.wires[i].toPort == portIdx) {
      return true;
    }
  }
  return false;
}

bool outputPortHasWire(GraphEditor* e, int nodeIdx, int portIdx) {
  for (int i = 0; i < e.wireCount; i = i + 1) {
    if (e.wires[i].fromNode == nodeIdx && e.wires[i].fromPort == portIdx) {
      return true;
    }
  }
  return false;
}
