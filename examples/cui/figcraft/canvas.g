// FigCraft Canvas Painting & Interactive Manipulation Engine.
// Renders dot grid, pan/zoom-transformed artboard, all DesignNode primitives,
// 12-column layout grid, wireframe mode, 8-handle resize/move, rubber-band tool creation,
// and keyboard shortcuts guarded by !gui::wantsKeyboard().

import std.gui;
import std.cui;
import std.string;
import std.math;
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
  float pi2 = (std::math::PI * 2.0) as float;
  float a0 = -(std::math::PI_2 as float);
  float a1 = a0 + pi2 * 0.44;
  float a2 = a1 + pi2 * 0.34;
  float a3 = a0 + pi2 * 0.98;

  gui::arc(draw, cx, cy, rad, a0, a1, thick, fcChartGreen());
  gui::arc(draw, cx, cy, rad, a1 + 0.06, a2, thick, fcChartBlue());
  gui::arc(draw, cx, cy, rad, a2 + 0.06, a3, thick, fcWarning());
}

Color applyBlendAndOpacity(Color base, float opacity, int blendMode) {
  if (base.a == 0) { return base; }
  Color c = base;
  int r = c.r as int;
  int g = c.g as int;
  int b = c.b as int;
  if (blendMode == 1) {
    // Darken
    r = (r * 86) / 100;
    g = (g * 86) / 100;
    b = (b * 86) / 100;
  } else if (blendMode == 2) {
    // Multiply
    r = (r * 76) / 100;
    g = (g * 76) / 100;
    b = (b * 80) / 100;
  } else if (blendMode == 3) {
    // Color Burn
    r = if (r > 32) (r - 28) * 90 / 100 else 0;
    g = if (g > 32) (g - 28) * 90 / 100 else 0;
    b = if (b > 32) (b - 28) * 90 / 100 else 0;
  } else if (blendMode == 4) {
    // Lighten
    r = r + ((255 - r) * 24) / 100;
    g = g + ((255 - g) * 24) / 100;
    b = b + ((255 - b) * 24) / 100;
  } else if (blendMode == 5) {
    // Screen
    r = r + ((255 - r) * 38) / 100;
    g = g + ((255 - g) * 38) / 100;
    b = b + ((255 - b) * 38) / 100;
  } else if (blendMode == 6) {
    // Overlay
    r = if (r > 128) gui::minf(255.0, (r as float) * 1.14) as int else ((r as float) * 0.86) as int;
    g = if (g > 128) gui::minf(255.0, (g as float) * 1.14) as int else ((g as float) * 0.86) as int;
    b = if (b > 128) gui::minf(255.0, (b as float) * 1.14) as int else ((b as float) * 0.86) as int;
  } else if (blendMode == 7) {
    // Soft Light
    r = if (r > 128) r + ((255 - r) * 14) / 100 else (r * 92) / 100;
    g = if (g > 128) g + ((255 - g) * 14) / 100 else (g * 92) / 100;
    b = if (b > 128) b + ((255 - b) * 14) / 100 else (b * 92) / 100;
  }
  c = gui::rgba(r, g, b, c.a as int);
  int alpha = (((c.a as float) * gui::clampf(opacity, 0.0, 1.0)) + 0.5) as int;
  if (alpha < 0) { alpha = 0; }
  if (alpha > 255) { alpha = 255; }
  return gui::fade(c, alpha);
}

CuiCorners nodeCorners(DesignNode* n, float scale, float nw, float nh, bool forceEllipse) {
  if (forceEllipse) {
    float er = gui::minf(nw, nh) * 0.5;
    return CuiCorners{tl: er, tr: er, br: er, bl: er};
  }
  if (n.independentCorners) {
    return CuiCorners{
      tl: gui::maxf(0.0, n.radiusTL * scale),
      tr: gui::maxf(0.0, n.radiusTR * scale),
      br: gui::maxf(0.0, n.radiusBR * scale),
      bl: gui::maxf(0.0, n.radiusBL * scale)
    };
  }
  float r = gui::maxf(0.0, n.radius * scale);
  return CuiCorners{tl: r, tr: r, br: r, bl: r};
}

GuiFont guiFontForRole(int fontRole) {
  if (fontRole == 1 || fontRole == 5 || fontRole == 7) { return gui::medium(); }
  if (fontRole == 2 || fontRole == 4) { return gui::display(); }
  if (fontRole == 3) { return gui::mono(); }
  return gui::body();
}

void drawOuterDropShadow(Draw* draw, DesignNode* n, float nx, float ny, float nw, float nh,
                         CuiCorners corners, float scale) {
  if (!n.dropShadowEnabled || !n.dropShadowVisible || n.dropShadowColor.a == 0) { return; }
  float sx = nx + n.dropShadowX * scale;
  float sy = ny + n.dropShadowY * scale;
  float spread = n.dropShadowSpread * scale;
  float blur = gui::maxf(0.0, n.dropShadowBlur * scale);
  int steps = ((blur * 0.5) + 1.0) as int;
  if (steps < 1) { steps = 1; }
  if (steps > 9) { steps = 9; }

  float baseA = (n.dropShadowColor.a as float) * gui::clampf(n.opacity, 0.0, 1.0);
  for (int s = steps - 1; s >= 0; s = s - 1) {
    float t = if (steps == 1) 0.0 else (s as float) / ((steps - 1) as float);
    float exp = spread + t * blur;
    float w = nw + exp * 2.0;
    float h = nh + exp * 2.0;
    if (w <= 1.0 || h <= 1.0) { continue; }
    float falloff = (1.0 - t * 0.78);
    int a = ((baseA * falloff * falloff) / ((steps as float) * 0.55 + 0.45)) as int;
    if (a < 2) { a = 2; }
    if (a > 240) { a = 240; }
    Color sc = gui::rgba(n.dropShadowColor.r as int, n.dropShadowColor.g as int, n.dropShadowColor.b as int, a);
    float radAdd = if (exp > 0.0) exp * 0.6 else 0.0;
    CuiCorners rc = CuiCorners{
      tl: gui::maxf(0.0, corners.tl + radAdd),
      tr: gui::maxf(0.0, corners.tr + radAdd),
      br: gui::maxf(0.0, corners.br + radAdd),
      bl: gui::maxf(0.0, corners.bl + radAdd)
    };
    cui_draw_rect(draw.ui, CuiRect{x: sx - exp, y: sy - exp, w: w, h: h}, rc,
                  CuiColor{r: sc.r, g: sc.g, b: sc.b, a: sc.a});
  }
}

void drawLayerBlurHalo(Draw* draw, DesignNode* n, float nx, float ny, float nw, float nh,
                       CuiCorners corners, float scale, Color fillC) {
  if (!n.layerBlurEnabled || !n.layerBlurVisible || n.layerBlur <= 0.0 || fillC.a == 0) { return; }
  float blur = n.layerBlur * scale;
  int steps = 4;
  for (int s = steps; s >= 1; s = s - 1) {
    float t = (s as float) / (steps as float);
    float exp = t * blur;
    int a = ((fillC.a as float) * (1.0 - t * 0.7) * 0.22) as int;
    if (a < 2) { continue; }
    CuiCorners rc = CuiCorners{
      tl: corners.tl + exp * 0.6,
      tr: corners.tr + exp * 0.6,
      br: corners.br + exp * 0.6,
      bl: corners.bl + exp * 0.6
    };
    cui_draw_rect(draw.ui, CuiRect{x: nx - exp, y: ny - exp, w: nw + exp * 2.0, h: nh + exp * 2.0}, rc,
                  CuiColor{r: fillC.r, g: fillC.g, b: fillC.b, a: a as uchar});
  }
}

void drawBackgroundBlur(Draw* draw, DesignNode* n, float nx, float ny, float nw, float nh,
                        CuiCorners corners, float scale) {
  if (!n.bgBlurEnabled || !n.bgBlurVisible || n.bgBlur <= 0.0 || n.bgBlurColor.a == 0) { return; }
  float blurFactor = gui::clampf(n.bgBlur / 36.0, 0.2, 1.0);
  float op = gui::clampf(n.opacity, 0.0, 1.0);
  int frostA = ((n.bgBlurColor.a as float) * op * (0.45 + blurFactor * 0.55)) as int;
  if (frostA < 4) { frostA = 4; }
  if (frostA > 240) { frostA = 240; }
  CuiColor frost = CuiColor{r: n.bgBlurColor.r, g: n.bgBlurColor.g, b: n.bgBlurColor.b, a: frostA as uchar};
  cui_draw_rect(draw.ui, CuiRect{x: nx, y: ny, w: nw, h: nh}, corners, frost);
  int rimA = ((64.0 * blurFactor) * op) as int;
  if (rimA > 4 && nw > 4.0 && nh > 4.0) {
    cui_draw_rect_border(draw.ui, CuiRect{x: nx + 1.0, y: ny + 1.0, w: nw - 2.0, h: nh - 2.0},
                         corners, CuiColor{r: 0, g: 0, b: 0, a: 0},
                         CuiColor{r: 255, g: 255, b: 255, a: rimA as uchar}, 1.0);
  }
}

void drawInnerShadow(Draw* draw, DesignNode* n, float nx, float ny, float nw, float nh,
                     CuiCorners corners, float scale) {
  if (!n.innerShadowEnabled || !n.innerShadowVisible || n.innerShadowColor.a == 0) { return; }
  if (nw <= 2.0 || nh <= 2.0) { return; }
  float ix = n.innerShadowX * scale;
  float iy = n.innerShadowY * scale;
  float blur = gui::maxf(2.0, n.innerShadowBlur * scale);
  float spread = n.innerShadowSpread * scale;
  float baseA = (n.innerShadowColor.a as float) * gui::clampf(n.opacity, 0.0, 1.0);

  gui::pushClip(draw, nx, ny, nw, nh);

  // Soft perimeter inset contours (matches rounded corners & ellipses)
  int rings = ((blur * 0.45) + 2.0) as int;
  if (rings < 2) { rings = 2; }
  if (rings > 8) { rings = 8; }
  float maxInset = gui::minf(gui::minf(nw, nh) * 0.45, blur * 0.55 + gui::maxf(0.0, spread));
  for (int k = 0; k < rings; k = k + 1) {
    float t = (k as float) / (rings as float);
    float inset = t * maxInset;
    float rw = nw - inset * 2.0;
    float rh = nh - inset * 2.0;
    if (rw <= 2.0 || rh <= 2.0) { break; }
    int a = ((baseA * (1.0 - t * 0.85)) / ((rings as float) * 0.55 + 0.5)) as int;
    if (a < 2) { a = 2; }
    if (a > 235) { a = 235; }
    CuiColor rcCol = CuiColor{r: n.innerShadowColor.r, g: n.innerShadowColor.g, b: n.innerShadowColor.b, a: a as uchar};
    CuiCorners rc = CuiCorners{
      tl: gui::maxf(0.0, corners.tl - inset),
      tr: gui::maxf(0.0, corners.tr - inset),
      br: gui::maxf(0.0, corners.br - inset),
      bl: gui::maxf(0.0, corners.bl - inset)
    };
    cui_draw_rect_border(draw.ui, CuiRect{x: nx + inset, y: ny + inset, w: rw, h: rh}, rc,
                         CuiColor{r: 0, g: 0, b: 0, a: 0}, rcCol, 1.6);
  }

  // Directional inner shadow falloff driven by (innerShadowX, innerShadowY, blur, spread)
  float topDepth = gui::maxf(0.0, iy + blur * 0.65 + spread);
  float botDepth = gui::maxf(0.0, -iy + blur * 0.65 + spread);
  float leftDepth = gui::maxf(0.0, ix + blur * 0.65 + spread);
  float rightDepth = gui::maxf(0.0, -ix + blur * 0.65 + spread);

  int dirSteps = 5;
  for (int s = 0; s < dirSteps; s = s + 1) {
    float t = (s as float) / (dirSteps as float);
    float wRatio = 1.0 - t;
    int a = ((baseA * wRatio * wRatio) / 3.4) as int;
    if (a < 2) { continue; }
    CuiColor dc = CuiColor{r: n.innerShadowColor.r, g: n.innerShadowColor.g, b: n.innerShadowColor.b, a: a as uchar};
    float bandFrac = (s as float + 1.0) / (dirSteps as float);
    if (topDepth > 0.5) {
      float th = gui::minf(nh * 0.5, topDepth * bandFrac);
      cui_draw_rect(draw.ui, CuiRect{x: nx, y: ny, w: nw, h: th},
                    CuiCorners{tl: corners.tl, tr: corners.tr, br: 0.0, bl: 0.0}, dc);
    }
    if (botDepth > 0.5) {
      float bh = gui::minf(nh * 0.5, botDepth * bandFrac);
      cui_draw_rect(draw.ui, CuiRect{x: nx, y: ny + nh - bh, w: nw, h: bh},
                    CuiCorners{tl: 0.0, tr: 0.0, br: corners.br, bl: corners.bl}, dc);
    }
    if (leftDepth > 0.5) {
      float lw = gui::minf(nw * 0.5, leftDepth * bandFrac);
      cui_draw_rect(draw.ui, CuiRect{x: nx, y: ny, w: lw, h: nh},
                    CuiCorners{tl: corners.tl, tr: 0.0, br: 0.0, bl: corners.bl}, dc);
    }
    if (rightDepth > 0.5) {
      float rww = gui::minf(nw * 0.5, rightDepth * bandFrac);
      cui_draw_rect(draw.ui, CuiRect{x: nx + nw - rww, y: ny, w: rww, h: nh},
                    CuiCorners{tl: 0.0, tr: corners.tr, br: corners.br, bl: 0.0}, dc);
    }
  }

  gui::popClip(draw);
}

void drawDashedRectBorder(Draw* draw, float rx, float ry, float rw, float rh, float thick, Color col) {
  float dash = gui::maxf(4.0, thick * 3.0);
  float gap = gui::maxf(3.0, thick * 2.2);
  float step = dash + gap;

  float px = rx;
  while (px < rx + rw) {
    float ex = gui::minf(rx + rw, px + dash);
    gui::line(draw, px, ry, ex, ry, thick, col);
    gui::line(draw, px, ry + rh, ex, ry + rh, thick, col);
    px = px + step;
  }
  float py = ry;
  while (py < ry + rh) {
    float ey = gui::minf(ry + rh, py + dash);
    gui::line(draw, rx, py, rx, ey, thick, col);
    gui::line(draw, rx + rw, py, rx + rw, ey, thick, col);
    py = py + step;
  }
}

void drawStyledStroke(Draw* draw, DesignNode* n, float nx, float ny, float nw, float nh,
                      CuiCorners corners, float scale, Color strokeC) {
  if (!n.strokeVisible || n.border <= 0.0 || strokeC.a == 0) { return; }
  float bw = gui::maxf(0.5, n.border * scale);
  float outset = 0.0;
  if (n.strokeAlign == 1) { outset = bw * 0.5; }
  else if (n.strokeAlign == 2) { outset = bw; }

  float sx = nx - outset;
  float sy = ny - outset;
  float sw = nw + outset * 2.0;
  float sh = nh + outset * 2.0;

  if (n.strokeStyle == 1) {
    drawDashedRectBorder(draw, sx, sy, sw, sh, bw, strokeC);
  } else {
    CuiCorners sc = CuiCorners{
      tl: gui::maxf(0.0, corners.tl + outset * 0.5),
      tr: gui::maxf(0.0, corners.tr + outset * 0.5),
      br: gui::maxf(0.0, corners.br + outset * 0.5),
      bl: gui::maxf(0.0, corners.bl + outset * 0.5)
    };
    cui_draw_rect_border(draw.ui, CuiRect{x: sx, y: sy, w: sw, h: sh}, sc,
                         CuiColor{r: 0, g: 0, b: 0, a: 0},
                         CuiColor{r: strokeC.r, g: strokeC.g, b: strokeC.b, a: strokeC.a}, bw);
  }
}

void drawFormattedLabel(Draw* draw, DesignNode* n, float nx, float ny, float nw, float nh,
                        float scale, Color inkC, const char* txtOverride) {
  const char* src = if (txtOverride != nullptr) txtOverride else &n.name[0];
  char[128] disp;
  std::string::copy_case(&disp[0], src, n.textCase, 128);
  int len = std::string::length(&disp[0]) as int;
  if (len == 0) { return; }

  GuiFont f = guiFontForRole(n.font);
  if (n.fontWeight >= 4 && n.font == 0) { f = gui::medium(); }
  float ts = gui::maxf(6.5, n.textSize * scale);
  float ls = n.letterSpacing * scale;
  float baseTw = gui::textWidth(draw, &disp[0], ts, f);
  float totalTw = baseTw + (if (len > 1) ((len - 1) as float) * ls else 0.0);

  float tx = nx;
  if (n.textAlign == 1) {
    tx = nx + (nw - totalTw) * 0.5;
  } else if (n.textAlign == 2) {
    tx = nx + nw - totalTw;
  }

  float ty = ny;
  if (n.textVAlign == 1) {
    ty = ny + (nh - ts * n.lineHeight) * 0.5;
  } else if (n.textVAlign == 2) {
    ty = ny + nh - ts * n.lineHeight;
  }

  // Optional Drop Shadow behind text glyphs
  if (n.kind == (NodeKind::NodeText as int) && n.dropShadowEnabled && n.dropShadowVisible && n.dropShadowColor.a > 0) {
    int sa = ((n.dropShadowColor.a as float) * gui::clampf(n.opacity, 0.0, 1.0)) as int;
    Color tsc = gui::rgba(n.dropShadowColor.r as int, n.dropShadowColor.g as int, n.dropShadowColor.b as int, sa);
    float sdx = n.dropShadowX * scale;
    float sdy = n.dropShadowY * scale;
    gui::text(draw, &disp[0], tx + sdx, ty + sdy, ts, f, tsc);
  }

  float boldStep = if (n.fontWeight >= 5) 0.55 * scale else if (n.fontWeight >= 3) 0.30 * scale else 0.0;
  float italicShift = if (n.fontItalic) 0.35 * scale else 0.0;

  if (ls > 0.25 || ls < -0.25) {
    float cx = tx;
    char[2] chBuf;
    chBuf[1] = '\0';
    for (int ci = 0; ci < len; ci = ci + 1) {
      chBuf[0] = disp[ci];
      if (boldStep > 0.05) {
        gui::text(draw, &chBuf[0], cx + boldStep + italicShift, ty, ts, f, inkC);
      }
      gui::text(draw, &chBuf[0], cx + italicShift, ty, ts, f, inkC);
      cx = cx + gui::textWidth(draw, &chBuf[0], ts, f) + ls;
    }
  } else {
    if (boldStep > 0.05) {
      gui::text(draw, &disp[0], tx + boldStep + italicShift, ty, ts, f, inkC);
    }
    gui::text(draw, &disp[0], tx + italicShift, ty, ts, f, inkC);
  }

  // Underline or Strikethrough
  if (n.textDecoration == 1) {
    float uy = ty + ts * 1.08;
    gui::line(draw, tx, uy, tx + totalTw, uy, gui::maxf(1.0, ts * 0.08), inkC);
  } else if (n.textDecoration == 2) {
    float syLine = ty + ts * 0.58;
    gui::line(draw, tx, syLine, tx + totalTw, syLine, gui::maxf(1.0, ts * 0.08), inkC);
  }
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

void drawEndpointCap(Draw* draw, float px, float py, float dirX, float dirY, int capKind, float head, float thick, Color col) {
  if (capKind == 2) {
    // Dot cap
    gui::circle(draw, px, py, gui::maxf(3.5, thick * 1.8), col);
  } else if (capKind == 1) {
    // Arrowhead pointing in (dirX, dirY)
    float perpX = -dirY;
    float perpY = dirX;
    float bx = px - dirX * head;
    float by = py - dirY * head;
    gui::line(draw, px, py, bx + perpX * head * 0.72, by + perpY * head * 0.72, thick, col);
    gui::line(draw, px, py, bx - perpX * head * 0.72, by - perpY * head * 0.72, thick, col);
  }
}

void drawArrowOrLineShape(Draw* draw, DesignNode* n, float nx, float ny, float nw, float nh,
                          float scale, Color fill, Color stroke) {
  Color col = if (n.strokeVisible && stroke.a > 0) stroke else fill;
  float thick = gui::maxf(1.5, (if (n.border > 0.0) n.border else 2.5) * scale);
  float cx = nx + nw * 0.5;
  float cy = ny + nh * 0.5;
  float halfLen = gui::maxf(4.0, nw * 0.5 - 4.0);
  float rad = (n.rotation * (std::math::PI as float)) / 180.0;
  float dx = std::math::cosf(rad);
  float dy = std::math::sinf(rad);
  float x0 = cx - dx * halfLen;
  float y0 = cy - dy * halfLen;
  float x1 = cx + dx * halfLen;
  float y1 = cy + dy * halfLen;

  if (n.strokeStyle == 1) {
    int segs = 8;
    for (int s = 0; s < segs; s = s + 2) {
      float t0 = (s as float) / (segs as float);
      float t1 = ((s + 1) as float) / (segs as float);
      gui::line(draw, x0 + (x1 - x0) * t0, y0 + (y1 - y0) * t0,
                x0 + (x1 - x0) * t1, y0 + (y1 - y0) * t1, thick, col);
    }
  } else {
    gui::line(draw, x0, y0, x1, y1, thick, col);
  }

  float head = gui::clampf(gui::minf(nw, nh) * (if (n.shapeRatio > 0.05) n.shapeRatio else 0.38), 6.0, 18.0);
  int sCap = n.arrowStartCap;
  int eCap = n.arrowEndCap;
  drawEndpointCap(draw, x0, y0, -dx, -dy, sCap, head, thick, col);
  drawEndpointCap(draw, x1, y1, dx, dy, eCap, head, thick, col);
}

void drawPolygonShape(Draw* draw, DesignNode* n, float nx, float ny, float nw, float nh,
                      float scale, Color fill, Color stroke) {
  int sides = n.shapeSides;
  if (sides < 3) { sides = 3; }
  if (sides > 12) { sides = 12; }
  float cx = nx + nw * 0.5;
  float cy = ny + nh * 0.5;
  float rx = nw * 0.48;
  float ry = nh * 0.48;
  float rotOffset = (n.rotation - 90.0) * (std::math::PI as float) / 180.0;
  float twoPi = (std::math::PI * 2.0) as float;

  if (n.fillVisible && fill.a > 0) {
    gui::rect(draw, nx + nw * 0.18, ny + nh * 0.18, nw * 0.64, nh * 0.64,
              gui::minf(nw, nh) * 0.30, gui::fade(fill, (fill.a as int) / 2));
  }
  Color lineCol = if (n.strokeVisible && stroke.a > 0) stroke else fill;
  float thick = gui::maxf(1.5, (if (n.border > 0.0) n.border else 2.0) * scale);
  float[12] vx;
  float[12] vy;
  for (int i = 0; i < sides; i = i + 1) {
    float ang = rotOffset + ((i as float) / (sides as float)) * twoPi;
    vx[i] = cx + std::math::cosf(ang) * rx;
    vy[i] = cy + std::math::sinf(ang) * ry;
  }
  for (int i = 0; i < sides; i = i + 1) {
    int j = (i + 1) % sides;
    gui::line(draw, vx[i], vy[i], vx[j], vy[j], thick, lineCol);
  }
}

void drawStarShape(Draw* draw, DesignNode* n, float nx, float ny, float nw, float nh,
                   float scale, Color fill, Color stroke) {
  int pts = n.shapeSides;
  if (pts < 3) { pts = 5; }
  if (pts > 12) { pts = 12; }
  float innerRatio = gui::clampf(if (n.shapeRatio > 0.05) n.shapeRatio else 0.42, 0.18, 0.85);
  float cx = nx + nw * 0.5;
  float cy = ny + nh * 0.5;
  float rx = nw * 0.49;
  float ry = nh * 0.49;
  float rotOffset = (n.rotation - 90.0) * (std::math::PI as float) / 180.0;
  float twoPi = (std::math::PI * 2.0) as float;
  int total = pts * 2;

  if (n.fillVisible && fill.a > 0) {
    gui::circle(draw, cx, cy, gui::minf(nw, nh) * innerRatio * 0.62, gui::fade(fill, (fill.a as int) / 2));
  }
  Color lineCol = if (n.strokeVisible && stroke.a > 0) stroke else fill;
  float thick = gui::maxf(1.5, (if (n.border > 0.0) n.border else 2.0) * scale);

  float[24] vx;
  float[24] vy;
  for (int i = 0; i < total; i = i + 1) {
    float ang = rotOffset + ((i as float) / (total as float)) * twoPi;
    float mult = if ((i % 2) == 0) 1.0 else innerRatio;
    vx[i] = cx + std::math::cosf(ang) * rx * mult;
    vy[i] = cy + std::math::sinf(ang) * ry * mult;
  }
  for (int i = 0; i < total; i = i + 1) {
    int j = (i + 1) % total;
    gui::line(draw, vx[i], vy[i], vx[j], vy[j], thick, lineCol);
  }
}

void drawImagePlaceholder(Draw* draw, float nx, float ny, float nw, float nh, float nr, Color fill, Color stroke) {
  Color bdr = if (stroke.a > 0) stroke else fcDesignBorder();
  gui::rectBorder(draw, nx, ny, nw, nh, nr, fill, bdr, 1.5);
  float pad = gui::clampf(gui::minf(nw, nh) * 0.14, 6.0, 20.0);
  float ix = nx + pad;
  float iy = ny + pad;
  float iw = nw - pad * 2.0;
  float ih = nh - pad * 2.0;
  if (iw > 16.0 && ih > 16.0) {
    Color peak = fcChartMint();
    Color ridge = fcChartGreen();
    gui::circle(draw, ix + iw * 0.25, iy + ih * 0.28, gui::minf(iw, ih) * 0.12, fcWarning());
    gui::line(draw, ix, iy + ih * 0.88, ix + iw * 0.36, iy + ih * 0.42, 2.0, ridge);
    gui::line(draw, ix + iw * 0.36, iy + ih * 0.42, ix + iw * 0.62, iy + ih * 0.72, 2.0, ridge);
    gui::line(draw, ix + iw * 0.50, iy + ih * 0.66, ix + iw * 0.76, iy + ih * 0.34, 2.0, peak);
    gui::line(draw, ix + iw * 0.76, iy + ih * 0.34, ix + iw, iy + ih * 0.88, 2.0, peak);
    gui::line(draw, ix, iy + ih * 0.88, ix + iw, iy + ih * 0.88, 1.5, bdr);
  }
}

void drawPencilStroke(Draw* draw, float nx, float ny, float nw, float nh, Color col) {
  float[9] ys;
  ys[0] = 0.75; ys[1] = 0.28; ys[2] = 0.65; ys[3] = 0.22; ys[4] = 0.58;
  ys[5] = 0.30; ys[6] = 0.72; ys[7] = 0.36; ys[8] = 0.52;
  float step = nw / 8.0;
  for (int i = 0; i < 8; i = i + 1) {
    float x0 = nx + (i as float) * step;
    float y0 = ny + nh * ys[i];
    float x1 = nx + ((i + 1) as float) * step;
    float y1 = ny + nh * ys[i + 1];
    gui::line(draw, x0, y0, x1, y1, 2.5, col);
  }
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
  gui::rect(draw, fx + 2.0, fy + 4.0, fw, fh, ed.stageRadius + 2.0, gui::rgba(0, 0, 0, 22));

  // Frame title label above top-left corner (UI3 style)
  gui::text(draw, &ed.stageName[0], fx, fy - 18.0, 10.5, gui::medium(),
            pickColor(ed.selected < 0 && !ed.presentMode, fcGreenDark(), fcSecondaryText(ed.darkTheme)));

  // Stage surface fill
  Color effStageBg = applyBlendAndOpacity(ed.stageBg, ed.stageOpacity, 0);
  if (ed.outlineMode) {
    gui::rectBorder(draw, fx, fy, fw, fh, ed.stageRadius, gui::clear(), fcSecondaryText(ed.darkTheme), 1.0);
  } else if (ed.fillVisible) {
    gui::rectBorder(draw, fx, fy, fw, fh, ed.stageRadius, effStageBg, fcDesignBorder(), 1.0);
  } else {
    gui::rectBorder(draw, fx, fy, fw, fh, ed.stageRadius, gui::clear(), fcBorder(ed.darkTheme), 1.0);
  }

  if (ed.clipContent) {
    gui::pushClip(draw, fx, fy, fw, fh);
  }

  // Render scene nodes
  for (int i = 0; i < ed.count; i = i + 1) {
    if (!isNodeVisibleInHierarchy(&ed, i)) { continue; }
    DesignNode* n = &ed.nodes[i];
    float nx = fx + n.x * scale;
    float ny = fy + n.y * scale;
    float nw = n.w * scale;
    float nh = n.h * scale;
    bool isEll = n.kind == (NodeKind::NodeEllipse as int);
    CuiCorners corners = nodeCorners(n, scale, nw, nh, isEll);

    int clipCount = 0;
    int pid = n.parentId;
    int hops = 0;
    while (pid >= 0 && hops < ed.count) {
      int pIdx = findNodeIndexById(&ed, pid);
      if (pIdx < 0) { break; }
      if (ed.nodes[pIdx].clipContent) {
        gui::pushClip(draw, fx + ed.nodes[pIdx].x * scale, fy + ed.nodes[pIdx].y * scale,
                      ed.nodes[pIdx].w * scale, ed.nodes[pIdx].h * scale);
        clipCount = clipCount + 1;
      }
      pid = ed.nodes[pIdx].parentId;
      hops = hops + 1;
    }

    if (ed.outlineMode) {
      Color wc = pickColor(ed.selected == i, fcGreen(), fcMutedText(ed.darkTheme));
      cui_draw_rect_border(draw.ui, CuiRect{x: nx, y: ny, w: nw, h: nh}, corners,
                           CuiColor{r: 0, g: 0, b: 0, a: 0},
                           CuiColor{r: wc.r, g: wc.g, b: wc.b, a: wc.a}, 1.0);
    } else {
      Color fillC = applyBlendAndOpacity(n.fill, n.opacity, n.blendMode);
      Color inkC = applyBlendAndOpacity(n.ink, n.opacity, n.blendMode);
      Color strokeC = applyBlendAndOpacity(n.stroke, n.opacity, n.blendMode);

      if (n.kind == (NodeKind::NodeRectangle as int) || n.kind == (NodeKind::NodeFrame as int)) {
        drawLayerBlurHalo(draw, n, nx, ny, nw, nh, corners, scale, fillC);
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawBackgroundBlur(draw, n, nx, ny, nw, nh, corners, scale);
        if (n.fillVisible && fillC.a > 0) {
          cui_draw_rect(draw.ui, CuiRect{x: nx, y: ny, w: nw, h: nh}, corners,
                        CuiColor{r: fillC.r, g: fillC.g, b: fillC.b, a: fillC.a});
        }
        drawInnerShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawStyledStroke(draw, n, nx, ny, nw, nh, corners, scale, strokeC);
        if (n.kind == (NodeKind::NodeFrame as int)) {
          gui::text(draw, &n.name[0], nx + 6.0, ny - 14.0, 9.0, gui::medium(), fcGreenDark());
        }
      } else if (n.kind == (NodeKind::NodeSection as int)) {
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawBackgroundBlur(draw, n, nx, ny, nw, nh, corners, scale);
        Color secFill = if (n.fillVisible && fillC.a > 0) gui::fade(fillC, gui::minf(80.0, fillC.a as float) as int) else gui::rgba(10, 207, 131, 18);
        cui_draw_rect(draw.ui, CuiRect{x: nx, y: ny, w: nw, h: nh}, corners,
                      CuiColor{r: secFill.r, g: secFill.g, b: secFill.b, a: secFill.a});
        drawInnerShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawStyledStroke(draw, n, nx, ny, nw, nh, corners, scale, strokeC);
        float labelW = gui::textWidth(draw, &n.name[0], 9.0, gui::medium()) + 14.0;
        gui::rect(draw, nx, ny - 18.0, labelW, 16.0, 5.0, fcGreen());
        gui::text(draw, &n.name[0], nx + 7.0, ny - 16.0, 8.5, gui::medium(), fcNavy());
      } else if (n.kind == (NodeKind::NodeSlice as int)) {
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        gui::rectBorder(draw, nx, ny, nw, nh, 3.0, gui::rgba(59, 130, 246, 16), strokeC, gui::maxf(1.0, n.border * scale));
        gui::rect(draw, nx, ny, 48.0, 16.0, 3.0, fcChartBlue());
        gui::text(draw, "SLICE", nx + 6.0, ny + 3.0, 8.0, gui::medium(), fcWhite());
      } else if (n.kind == (NodeKind::NodeEllipse as int)) {
        float hole = gui::clampf(n.shapeRatio, 0.0, 0.85);
        drawLayerBlurHalo(draw, n, nx, ny, nw, nh, corners, scale, fillC);
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawBackgroundBlur(draw, n, nx, ny, nw, nh, corners, scale);
        if (hole > 0.02) {
          float rad = gui::minf(nw, nh) * 0.5;
          float thick = gui::maxf(2.0, rad * (1.0 - hole));
          float fullArc = (std::math::PI * 2.0) as float;
          gui::arc(draw, nx + nw * 0.5, ny + nh * 0.5, rad - thick * 0.5, 0.0, fullArc, thick, fillC);
        } else {
          if (n.fillVisible && fillC.a > 0) {
            cui_draw_rect(draw.ui, CuiRect{x: nx, y: ny, w: nw, h: nh}, corners,
                          CuiColor{r: fillC.r, g: fillC.g, b: fillC.b, a: fillC.a});
          }
          drawInnerShadow(draw, n, nx, ny, nw, nh, corners, scale);
          drawStyledStroke(draw, n, nx, ny, nw, nh, corners, scale, strokeC);
        }
      } else if (n.kind == (NodeKind::NodeButton as int)) {
        drawLayerBlurHalo(draw, n, nx, ny, nw, nh, corners, scale, fillC);
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawBackgroundBlur(draw, n, nx, ny, nw, nh, corners, scale);
        if (n.fillVisible && fillC.a > 0) {
          cui_draw_rect(draw.ui, CuiRect{x: nx, y: ny, w: nw, h: nh}, corners,
                        CuiColor{r: fillC.r, g: fillC.g, b: fillC.b, a: fillC.a});
        }
        drawInnerShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawStyledStroke(draw, n, nx, ny, nw, nh, corners, scale, strokeC);
        drawFormattedLabel(draw, n, nx, ny, nw, nh, scale, inkC, nullptr);
      } else if (n.kind == (NodeKind::NodeText as int)) {
        drawFormattedLabel(draw, n, nx, ny, nw, nh, scale, inkC, nullptr);
      } else if (n.kind == (NodeKind::NodeChart as int)) {
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawGroupedBars(draw, nx, ny, nw, nh, scale, fillC);
      } else if (n.kind == (NodeKind::NodeDonut as int)) {
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawSegmentedDonut(draw, nx, ny, nw, nh);
      } else if (n.kind == (NodeKind::NodeLine as int)) {
        if (nh <= 28.0 * scale) {
          drawArrowOrLineShape(draw, n, nx, ny, nw, nh, scale, fillC, strokeC);
        } else {
          drawTrendPolyline(draw, nx, ny, nw, nh, fillC, n.font);
        }
      } else if (n.kind == (NodeKind::NodeArrow as int)) {
        drawArrowOrLineShape(draw, n, nx, ny, nw, nh, scale, fillC, strokeC);
      } else if (n.kind == (NodeKind::NodePolygon as int)) {
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawPolygonShape(draw, n, nx, ny, nw, nh, scale, fillC, strokeC);
      } else if (n.kind == (NodeKind::NodeStar as int)) {
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawStarShape(draw, n, nx, ny, nw, nh, scale, fillC, strokeC);
      } else if (n.kind == (NodeKind::NodeImage as int)) {
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        drawBackgroundBlur(draw, n, nx, ny, nw, nh, corners, scale);
        drawImagePlaceholder(draw, nx, ny, nw, nh, corners.tl, fillC, strokeC);
        drawInnerShadow(draw, n, nx, ny, nw, nh, corners, scale);
      } else if (n.kind == (NodeKind::NodeSparkline as int)) {
        drawTrendPolyline(draw, nx, ny, nw, nh, fillC, n.font);
      } else if (n.kind == (NodeKind::NodePen as int)) {
        drawVectorDiamond(draw, nx, ny, nw, nh, fillC, strokeC);
      } else if (n.kind == (NodeKind::NodePencil as int)) {
        drawPencilStroke(draw, nx, ny, nw, nh, fillC);
      } else if (n.kind == (NodeKind::NodeComment as int)) {
        drawOuterDropShadow(draw, n, nx, ny, nw, nh, corners, scale);
        cui_draw_rect_border(draw.ui, CuiRect{x: nx, y: ny, w: nw, h: nh}, corners,
                             CuiColor{r: fillC.r, g: fillC.g, b: fillC.b, a: fillC.a},
                             CuiColor{r: strokeC.r, g: strokeC.g, b: strokeC.b, a: strokeC.a},
                             gui::maxf(1.0, n.border * scale));
        drawInnerShadow(draw, n, nx, ny, nw, nh, corners, scale);
        gui::rect(draw, nx + 10.0, ny + 8.0, 8.0, 8.0, 4.0, fcGreen());
        const char* noteTxt = if (n.body[0] != '\0') &n.body[0] else &n.name[0];
        drawFormattedLabel(draw, n, nx + 24.0, ny, gui::maxf(20.0, nw - 30.0), nh, scale, inkC, noteTxt);
      }
    }

    for (int pc = 0; pc < clipCount; pc = pc + 1) {
      gui::popClip(draw);
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

  // Container drop-target highlight during canvas reparenting or asset drop
  if (ed.hoverParentIdx >= 0 && ed.hoverParentIdx < ed.count) {
    DesignNode* hp = &ed.nodes[ed.hoverParentIdx];
    float hpx = fx + hp.x * scale;
    float hpy = fy + hp.y * scale;
    float hpw = hp.w * scale;
    float hph = hp.h * scale;
    gui::rectBorder(draw, hpx - 2.0, hpy - 2.0, hpw + 4.0, hph + 4.0, 6.0,
                    gui::rgba(10, 207, 131, 20), fcGreen(), 2.0);
    char[80] dropBadge;
    std::string::copy(&dropBadge[0], "Drop inside ", 80);
    std::string::append_into(&dropBadge[0], &hp.name[0], 80);
    float btw = gui::textWidth(draw, &dropBadge[0], 8.5, gui::medium()) + 12.0;
    float bty = gui::maxf(draw.rect.y + 4.0, hpy - 20.0);
    gui::rect(draw, hpx, bty, btw, 16.0, 4.0, fcGreen());
    gui::text(draw, &dropBadge[0], hpx + 6.0, bty + 2.5, 8.5, gui::medium(), fcNavy());
  }

  // Live canvas footprint preview during asset drag-and-drop
  if (ed.assetDragActive) {
    float mx = gui::mouseX();
    float my = gui::mouseY();
    if (gui::hasPoint(draw.rect, mx, my) && !mouseInsideFloatingOverlay(mx, my)) {
      float dropCx = screenToDesignX(&ed, mx);
      float dropCy = screenToDesignY(&ed, my);
      Rect fp = computeDropFootprint(&ed, ed.assetDragIsSection, ed.assetDragKind, dropCx, dropCy);
      float px = fx + fp.x * scale;
      float py = fy + fp.y * scale;
      float pw = fp.w * scale;
      float ph = fp.h * scale;
      gui::rectBorder(draw, px, py, pw, ph, 8.0, gui::rgba(10, 207, 131, 34), fcGreen(), 2.0);
    }
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
    float previewRadius = if (ed.tool == (ToolKind::ToolEllipse as int)) gui::minf(sw, sh) * 0.5 else 4.0;
    gui::rectBorder(draw, sx, sy, sw, sh, previewRadius, gui::rgba(10, 207, 131, 32), fcGreen(), 1.5);
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

    // Smart alignment & Center-Center snapping guides overlay
    if (ed.snapEnabled && ed.dragging && (ed.snapCountX > 0 || ed.snapCountY > 0 || ed.snapCenterCenter)) {
      for (int i = 0; i < ed.snapCountX; i = i + 1) {
        float lx = fx + ed.snapLineX[i] * scale;
        float ly0 = fy + ed.snapLineY0[i] * scale - 14.0;
        float ly1 = fy + ed.snapLineY1[i] * scale + 14.0;
        Color lcol = if (ed.snapKindX[i] == 1) fcSnapCenter() else fcSnapLine();
        float lthick = if (ed.snapKindX[i] == 1) 1.5 else 1.1;
        gui::line(draw, lx, ly0, lx, ly1, lthick, lcol);
        gui::line(draw, lx - 3.5, ly0, lx + 3.5, ly0, 1.0, lcol);
        gui::line(draw, lx - 3.5, ly1, lx + 3.5, ly1, 1.0, lcol);
      }
      for (int i = 0; i < ed.snapCountY; i = i + 1) {
        float ly = fy + ed.snapLineY[i] * scale;
        float lx0 = fx + ed.snapLineX0[i] * scale - 14.0;
        float lx1 = fx + ed.snapLineX1[i] * scale + 14.0;
        Color lcol = if (ed.snapKindY[i] == 1) fcSnapCenter() else fcSnapLine();
        float lthick = if (ed.snapKindY[i] == 1) 1.5 else 1.1;
        gui::line(draw, lx0, ly, lx1, ly, lthick, lcol);
        gui::line(draw, lx0, ly - 3.5, lx0, ly + 3.5, 1.0, lcol);
        gui::line(draw, lx1, ly - 3.5, lx1, ly + 3.5, 1.0, lcol);
      }
      if (ed.snapCenterCenter) {
        float ccx = fx + ed.snapCenterX * scale;
        float ccy = fy + ed.snapCenterY * scale;
        gui::circle(draw, ccx, ccy, 4.5, fcSnapCenter());
        gui::circle(draw, ccx, ccy, 2.0, fcWhite());
        gui::line(draw, ccx - 9.0, ccy, ccx + 9.0, ccy, 1.5, fcSnapCenter());
        gui::line(draw, ccx, ccy - 9.0, ccx, ccy + 9.0, 1.5, fcSnapCenter());
        if (ed.snapBadgeText[0] != '\0') {
          float btw = gui::textWidth(draw, &ed.snapBadgeText[0], 8.5, gui::medium()) + 12.0;
          float bbx = ccx + 10.0;
          float bby = ccy - 22.0;
          gui::rect(draw, bbx, bby, btw, 17.0, 4.0, fcSnapBadgeBg());
          gui::text(draw, &ed.snapBadgeText[0], bbx + 6.0, bby + 3.0, 8.5, gui::medium(), fcWhite());
        }
      }
    }
  }

  gui::popClip(draw);
}

bool mouseInsideFloatingOverlay(float mx, float my) {
  Rect tb = gui::widgetRect("fc-toolbar");
  if (tb.w > 0.0 && gui::hasPoint(tb, mx, my)) { return true; }
  Rect tf = gui::widgetRect("fc-tool-flyout");
  if (tf.w > 0.0 && gui::hasPoint(tf, mx, my)) { return true; }
  Rect cp = gui::widgetRect("fc-color-picker");
  if (cp.w > 0.0 && gui::hasPoint(cp, mx, my)) { return true; }
  Rect mm = gui::widgetRect("fc-main-menu");
  if (mm.w > 0.0 && gui::hasPoint(mm, mx, my)) { return true; }
  Rect em = gui::widgetRect("fc-exit-modal");
  if (em.w > 0.0 && gui::hasPoint(em, mx, my)) { return true; }
  Rect sm = gui::widgetRect("fc-save-modal");
  if (sm.w > 0.0 && gui::hasPoint(sm, mx, my)) { return true; }
  Rect xm = gui::widgetRect("fc-export-modal");
  if (xm.w > 0.0 && gui::hasPoint(xm, mx, my)) { return true; }
  Rect qa = gui::widgetRect("fc-actions-bar");
  if (qa.w > 0.0 && gui::hasPoint(qa, mx, my)) { return true; }
  Rect hc = gui::widgetRect("fc-help-card");
  if (hc.w > 0.0 && gui::hasPoint(hc, mx, my)) { return true; }
  Rect lc = gui::widgetRect("fc-expand-left");
  if (lc.w > 0.0 && gui::hasPoint(lc, mx, my)) { return true; }
  Rect rc = gui::widgetRect("fc-expand-right");
  if (rc.w > 0.0 && gui::hasPoint(rc, mx, my)) { return true; }
  Rect pb = gui::widgetRect("fc-present-bar");
  if (pb.w > 0.0 && gui::hasPoint(pb, mx, my)) { return true; }
  return false;
}

bool isRubberBandTool(int toolIdx) {
  return toolIdx == (ToolKind::ToolFrame as int) ||
         toolIdx == (ToolKind::ToolSection as int) ||
         toolIdx == (ToolKind::ToolSlice as int) ||
         toolIdx == (ToolKind::ToolRect as int) ||
         toolIdx == (ToolKind::ToolLine as int) ||
         toolIdx == (ToolKind::ToolArrow as int) ||
         toolIdx == (ToolKind::ToolEllipse as int) ||
         toolIdx == (ToolKind::ToolPolygon as int) ||
         toolIdx == (ToolKind::ToolStar as int) ||
         toolIdx == (ToolKind::ToolImage as int);
}

void spawnRubberBandShape(Editor* e, float rx0, float ry0, float rw, float rh) {
  int t = e.tool;
  if (t == (ToolKind::ToolFrame as int)) {
    addNodeToEditor(e, NodeKind::NodeFrame, "Frame", "",
                    rx0, ry0, rw, rh, fcWhite(), gui::clear(), fcBorder(e.darkTheme), 6.0, 1.0, 0.0, 0);
  } else if (t == (ToolKind::ToolSection as int)) {
    addNodeToEditor(e, NodeKind::NodeSection, "Section", "",
                    rx0, ry0, rw, rh, fcGreenSoft(e.darkTheme), gui::clear(), fcGreen(), 10.0, 1.5, 0.0, 0);
  } else if (t == (ToolKind::ToolSlice as int)) {
    addNodeToEditor(e, NodeKind::NodeSlice, "Export Slice", "",
                    rx0, ry0, rw, rh, gui::clear(), fcWhite(), fcChartBlue(), 3.0, 1.5, 0.0, 0);
  } else if (t == (ToolKind::ToolLine as int)) {
    float lh = if (rh < 20.0) 14.0 else rh;
    addNodeToEditor(e, NodeKind::NodeLine, "Line", "",
                    rx0, ry0, rw, lh, fcNavy(), gui::clear(), fcNavy(), 0.0, 2.0, 0.0, 0);
  } else if (t == (ToolKind::ToolArrow as int)) {
    float ah = if (rh < 24.0) 24.0 else rh;
    addNodeToEditor(e, NodeKind::NodeArrow, "Arrow", "",
                    rx0, ry0, rw, ah, fcGreenDark(), gui::clear(), fcGreenDark(), 0.0, 2.5, 0.0, 0);
  } else if (t == (ToolKind::ToolEllipse as int)) {
    float side = gui::maxf(rw, rh);
    addNodeToEditor(e, NodeKind::NodeEllipse, "Ellipse", "",
                    rx0, ry0, rw, rh, fcChartBlue(), gui::clear(), gui::clear(), side * 0.5, 0.0, 0.0, 0);
  } else if (t == (ToolKind::ToolPolygon as int)) {
    addNodeToEditor(e, NodeKind::NodePolygon, "Polygon", "",
                    rx0, ry0, rw, rh, fcPurple(), gui::clear(), fcPurple(), 0.0, 2.0, 0.0, 0);
  } else if (t == (ToolKind::ToolStar as int)) {
    addNodeToEditor(e, NodeKind::NodeStar, "Star", "",
                    rx0, ry0, rw, rh, fcWarning(), gui::clear(), fcWarning(), 0.0, 2.0, 0.0, 0);
  } else if (t == (ToolKind::ToolImage as int)) {
    addNodeToEditor(e, NodeKind::NodeImage, "Image Placeholder", "",
                    rx0, ry0, rw, rh, fcWhite(), fcNavy(), fcDesignBorder(), 10.0, 1.5, 0.0, 0);
  } else {
    addScRect(e, "Rectangle", rx0, ry0, rw, rh, fcGreen(), 8.0, 0.0, gui::clear());
  }
}

void handleGlobalOverlayDismiss() {
  if (!gui::mouseClicked()) { return; }
  float mx = gui::mouseX();
  float my = gui::mouseY();

  if (ed.showMainMenu) {
    Rect mm = gui::widgetRect("fc-main-menu");
    Rect logo = gui::widgetRect("fc-rail-logo");
    if (!gui::hasPoint(mm, mx, my) && !gui::hasPoint(logo, mx, my)) {
      ed.showMainMenu = false;
    }
  }
  if (ed.openFlyout >= 0) {
    Rect tf = gui::widgetRect("fc-tool-flyout");
    Rect tb = gui::widgetRect("fc-toolbar");
    if (!gui::hasPoint(tf, mx, my) && !gui::hasPoint(tb, mx, my)) {
      ed.openFlyout = -1;
    }
  }
}

void handleGlobalShortcuts() {
  if (gui::wantsKeyboard()) { return; }
  if (gui::keyPressed(GuiKey::GuiKeyEscape)) {
    if (ed.showExitPrompt) { ed.showExitPrompt = false; }
    else if (ed.showSaveAsModal) { ed.showSaveAsModal = false; }
    else if (ed.showExportModal) { ed.showExportModal = false; }
    else if (ed.showColorPicker) { ed.showColorPicker = false; }
    else if (ed.showMainMenu) { ed.showMainMenu = false; }
    else if (ed.openFlyout >= 0) { ed.openFlyout = -1; }
    else if (ed.presentMode) { ed.presentMode = false; }
    else if (ed.showHelp) { ed.showHelp = false; }
    else if (ed.showActions) { ed.showActions = false; }
    else if (!ed.showHome && ed.tool != (ToolKind::ToolMove as int)) { selectTool(&ed, ToolKind::ToolMove as int); }
    else if (!ed.showHome) { ed.selected = -1; }
  }
}

const char* sectionWidgetId(int k) {
  if (k == 0) { return "fc-sec-navbar"; }
  if (k == 1) { return "fc-sec-hero"; }
  if (k == 2) { return "fc-sec-cards"; }
  if (k == 3) { return "fc-sec-login"; }
  if (k == 4) { return "fc-sec-kpi"; }
  return "fc-sec-footer";
}

const char* assetWidgetId(int k) {
  if (k == 0) { return "fc-asset-button"; }
  if (k == 1) { return "fc-asset-outline"; }
  if (k == 2) { return "fc-asset-card"; }
  if (k == 3) { return "fc-asset-input"; }
  if (k == 4) { return "fc-asset-badge"; }
  if (k == 5) { return "fc-asset-chart"; }
  if (k == 6) { return "fc-asset-spark"; }
  if (k == 7) { return "fc-asset-donut"; }
  if (k == 8) { return "fc-asset-avatar"; }
  if (k == 9) { return "fc-asset-toggle"; }
  if (k == 10) { return "fc-asset-image"; }
  return "fc-asset-comment";
}

void handleLayerDragInput() {
  bool eligible = !ed.showHome && !ed.presentMode && !ed.leftCollapsed &&
                  ed.leftTab == (LeftTab::TabFile as int) &&
                  !ed.showExitPrompt && !ed.showSaveAsModal && !ed.showExportModal &&
                  !ed.showMainMenu && !ed.showColorPicker;
  if (!eligible) {
    ed.layerDragArmed = false;
    ed.layerDragActive = false;
    ed.layerDragNodeIdx = -1;
    ed.layerDropTargetIdx = -2;
    ed.layerDropMode = 0;
    return;
  }

  buildLayerTreeCache(&ed);
  float mx = gui::mouseX();
  float my = gui::mouseY();

  if (gui::mouseClicked()) {
    Rect scrollR = gui::widgetRect("fc-layers-scroll");
    if (scrollR.w > 0.0 && gui::hasPoint(scrollR, mx, my)) {
      for (int t = 0; t < ed.layerTreeCount; t = t + 1) {
        int ni = ed.layerTreeOrder[t];
        if (ni < 0 || ni >= ed.count) { continue; }
        Rect rowR = gui::widgetRect(&ed.nodes[ni].rowId[0]);
        if (rowR.w > 0.0 && gui::hasPoint(rowR, mx, my)) {
          int depth = ed.layerTreeDepth[t];
          bool hasExpand = ed.layerTreeHasKids[t] || isNodeContainerKind(ed.nodes[ni].kind);
          float leftPad = 8.0 + (depth as float) * 14.0;
          if (hasExpand && mx <= rowR.x + leftPad + 16.0) { break; }
          if (mx >= rowR.x + rowR.w - 26.0) { break; }
          ed.layerDragArmed = true;
          ed.layerDragActive = false;
          ed.layerDragNodeIdx = ni;
          ed.layerDragMouseX = mx;
          ed.layerDragMouseY = my;
          ed.layerDropTargetIdx = -2;
          ed.layerDropMode = 0;
          break;
        }
      }
    }
  }

  if (ed.layerDragArmed) {
    if (gui::mouseDown()) {
      float ddx = mx - ed.layerDragMouseX;
      float ddy = my - ed.layerDragMouseY;
      if (ddx * ddx + ddy * ddy >= 25.0) {
        ed.layerDragActive = true;
      }
      if (ed.layerDragActive) {
        int dragIdx = ed.layerDragNodeIdx;
        if (dragIdx < 0 || dragIdx >= ed.count) {
          ed.layerDragArmed = false;
          ed.layerDragActive = false;
          ed.layerDragNodeIdx = -1;
          ed.layerDropTargetIdx = -2;
          return;
        }
        ed.layerDropTargetIdx = -2;
        Rect rootR = gui::widgetRect("fc-layer-root");
        if (rootR.w > 0.0 && gui::hasPoint(rootR, mx, my)) {
          ed.layerDropTargetIdx = -1;
          ed.layerDropMode = 1;
        } else {
          for (int t = 0; t < ed.layerTreeCount; t = t + 1) {
            int ni = ed.layerTreeOrder[t];
            if (ni < 0 || ni >= ed.count) { continue; }
            if (ni == dragIdx || isNodeDescendant(&ed, ni, ed.nodes[dragIdx].id)) { continue; }
            Rect rowR = gui::widgetRect(&ed.nodes[ni].rowId[0]);
            if (rowR.w > 0.0 && gui::hasPoint(rowR, mx, my)) {
              float relY = (my - rowR.y) / gui::maxf(1.0, rowR.h);
              ed.layerDropTargetIdx = ni;
              if (isNodeContainerKind(ed.nodes[ni].kind)) {
                if (relY < 0.30) { ed.layerDropMode = 0; }
                else if (relY > 0.70) { ed.layerDropMode = 2; }
                else { ed.layerDropMode = 1; }
              } else {
                if (relY < 0.50) { ed.layerDropMode = 0; }
                else { ed.layerDropMode = 2; }
              }
              break;
            }
          }
        }
      }
    } else {
      if (ed.layerDragActive && ed.layerDropTargetIdx >= -1) {
        reorderLayerRelative(&ed, ed.layerDragNodeIdx, ed.layerDropTargetIdx, ed.layerDropMode);
        buildLayerTreeCache(&ed);
      }
      ed.layerDragArmed = false;
      ed.layerDragActive = false;
      ed.layerDragNodeIdx = -1;
      ed.layerDropTargetIdx = -2;
      ed.layerDropMode = 0;
    }
  }
}

void handleAssetDragInput() {
  bool eligible = !ed.showHome && !ed.presentMode && !ed.leftCollapsed &&
                  ed.leftTab == (LeftTab::TabAssets as int) &&
                  !ed.showExitPrompt && !ed.showSaveAsModal && !ed.showExportModal &&
                  !ed.showMainMenu && !ed.showColorPicker;
  if (!eligible) {
    if (ed.assetDragActive) { ed.hoverParentIdx = -1; }
    ed.assetDragArmed = false;
    ed.assetDragActive = false;
    return;
  }

  float mx = gui::mouseX();
  float my = gui::mouseY();

  if (gui::mouseClicked()) {
    Rect scrollR = gui::widgetRect("fc-assets-scroll");
    if (scrollR.w > 0.0 && gui::hasPoint(scrollR, mx, my)) {
      bool picked = false;
      for (int k = 0; k < 6; k = k + 1) {
        Rect cr = gui::widgetRect(sectionWidgetId(k));
        if (cr.w > 0.0 && gui::hasPoint(cr, mx, my)) {
          ed.assetDragArmed = true;
          ed.assetDragActive = false;
          ed.assetDragIsSection = true;
          ed.assetDragKind = k;
          ed.assetDragMouseX = mx;
          ed.assetDragMouseY = my;
          picked = true;
          break;
        }
      }
      if (!picked) {
        for (int k = 0; k < 12; k = k + 1) {
          Rect cr = gui::widgetRect(assetWidgetId(k));
          if (cr.w > 0.0 && gui::hasPoint(cr, mx, my)) {
            ed.assetDragArmed = true;
            ed.assetDragActive = false;
            ed.assetDragIsSection = false;
            ed.assetDragKind = k;
            ed.assetDragMouseX = mx;
            ed.assetDragMouseY = my;
            break;
          }
        }
      }
    }
  }

  if (ed.assetDragArmed) {
    bool overCanvas = gui::hasPoint(ed.canvasRect, mx, my) && !mouseInsideFloatingOverlay(mx, my);
    if (gui::mouseDown()) {
      float ddx = mx - ed.assetDragMouseX;
      float ddy = my - ed.assetDragMouseY;
      if (ddx * ddx + ddy * ddy >= 36.0) {
        ed.assetDragActive = true;
      }
      if (ed.assetDragActive && overCanvas) {
        float dx = screenToDesignX(&ed, mx);
        float dy = screenToDesignY(&ed, my);
        ed.hoverParentIdx = findContainerAtPoint(&ed, dx, dy, -1);
      } else {
        ed.hoverParentIdx = -1;
      }
    } else {
      if (!ed.assetDragActive) {
        if (ed.assetDragIsSection) {
          insertPrebuiltSection(&ed, ed.assetDragKind);
        } else {
          insertComponentAsset(&ed, ed.assetDragKind);
        }
      } else if (overCanvas) {
        float dx = screenToDesignX(&ed, mx);
        float dy = screenToDesignY(&ed, my);
        int pIdx = findContainerAtPoint(&ed, dx, dy, -1);
        int pid = if (pIdx >= 0) ed.nodes[pIdx].id else -1;
        if (ed.assetDragIsSection) {
          insertPrebuiltSectionAt(&ed, ed.assetDragKind, dx, dy, pid);
        } else {
          insertComponentAssetAt(&ed, ed.assetDragKind, dx, dy, pid);
        }
      }
      ed.assetDragArmed = false;
      ed.assetDragActive = false;
      ed.hoverParentIdx = -1;
    }
  }
}

void handleCanvasInput() {
  handleGlobalShortcuts();
  handleGlobalOverlayDismiss();
  syncLiveInspectorEdits(&ed);
  if (ed.showHome || ed.showExitPrompt || ed.showSaveAsModal || ed.showExportModal) {
    ed.layerDragArmed = false;
    ed.layerDragActive = false;
    ed.assetDragArmed = false;
    ed.assetDragActive = false;
    ed.hoverParentIdx = -1;
    return;
  }

  bool dragWasActive = ed.layerDragActive || ed.assetDragActive;
  handleLayerDragInput();
  handleAssetDragInput();
  if (dragWasActive || ed.layerDragActive || ed.assetDragActive) {
    return;
  }

  if (!gui::wantsKeyboard()) {
    if (!ed.presentMode) {
      if (gui::keyPressed(GuiKey::GuiKeyV)) { selectTool(&ed, ToolKind::ToolMove as int); }
      if (gui::keyPressed(GuiKey::GuiKeyH)) { selectTool(&ed, ToolKind::ToolHand as int); }
      if (gui::keyPressed(GuiKey::GuiKeyF)) { selectTool(&ed, ToolKind::ToolFrame as int); }
      if (gui::keyPressed(GuiKey::GuiKeyR)) { selectTool(&ed, ToolKind::ToolRect as int); }
      if (gui::keyPressed(GuiKey::GuiKeyP)) { selectTool(&ed, ToolKind::ToolPen as int); }
      if (gui::keyPressed(GuiKey::GuiKeyT)) { selectTool(&ed, ToolKind::ToolText as int); }
      if (gui::keyPressed(GuiKey::GuiKeyC)) { selectTool(&ed, ToolKind::ToolComment as int); }
      if (gui::keyPressed(GuiKey::GuiKeyK)) { ed.showActions = !ed.showActions; }
      if (gui::keyPressed(GuiKey::GuiKeyG)) { ed.showGrid = !ed.showGrid; }
      if (gui::keyPressed(GuiKey::GuiKeyN)) { toggleSnapping(&ed); }
      if (gui::keyPressed(GuiKey::GuiKeyL)) { selectTool(&ed, ToolKind::ToolLine as int); }
      if (guiCtx != nullptr && cui_key_pressed(guiCtx, CuiKey::KeyO)) { selectTool(&ed, ToolKind::ToolEllipse as int); }
      if (guiCtx != nullptr && cui_key_pressed(guiCtx, CuiKey::KeyS)) { selectTool(&ed, ToolKind::ToolSlice as int); }
      if (guiCtx != nullptr && cui_key_pressed(guiCtx, CuiKey::KeyI)) { selectTool(&ed, ToolKind::ToolImage as int); }
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

    if (gui::keyDown(GuiKey::GuiKeySpace) || gui::middleDown() || ed.tool == (ToolKind::ToolHand as int)) {
      ed.panning = true;
      ed.dragStartX = ed.offsetX;
      ed.dragStartY = ed.offsetY;
      ed.dragMouseX = mx;
      ed.dragMouseY = my;
      return;
    }

    if (ed.tool == (ToolKind::ToolMove as int) || ed.tool == (ToolKind::ToolScale as int)) {
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
    } else if (isRubberBandTool(ed.tool)) {
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
      markDirty(&ed);
      selectTool(&ed, ToolKind::ToolMove as int);
      refreshInspectorLabels(&ed);
    } else if (ed.tool == (ToolKind::ToolPencil as int)) {
      addNodeToEditor(&ed, NodeKind::NodePencil, "Freehand Stroke", "",
                      dx - 60.0, dy - 30.0, 120.0, 60.0,
                      fcChartGreen(), gui::clear(), fcChartGreen(), 0.0, 2.5, 0.0, 0);
      ed.selected = ed.count - 1;
      markDirty(&ed);
      selectTool(&ed, ToolKind::ToolMove as int);
      refreshInspectorLabels(&ed);
    } else if (ed.tool == (ToolKind::ToolText as int)) {
      addScText(&ed, "New Heading", dx, dy, 180.0, 32.0, 18.0, fcNavy(), 1);
      ed.selected = ed.count - 1;
      markDirty(&ed);
      selectTool(&ed, ToolKind::ToolMove as int);
      refreshInspectorLabels(&ed);
    } else if (ed.tool == (ToolKind::ToolBodyText as int)) {
      addScText(&ed, "Body copy for layout specification and notes.", dx, dy, 280.0, 24.0, 12.0, fcTitleMuted(), 0);
      ed.selected = ed.count - 1;
      markDirty(&ed);
      selectTool(&ed, ToolKind::ToolMove as int);
      refreshInspectorLabels(&ed);
    } else if (ed.tool == (ToolKind::ToolBadge as int)) {
      addScButton(&ed, "Status Pill", dx, dy, 124.0, 30.0, fcGreen(), fcNavy());
      ed.selected = ed.count - 1;
      markDirty(&ed);
      selectTool(&ed, ToolKind::ToolMove as int);
      refreshInspectorLabels(&ed);
    } else if (ed.tool == (ToolKind::ToolComment as int)) {
      addNodeToEditor(&ed, NodeKind::NodeComment, "Review Note", "Looks crisp!",
                      dx, dy, 136.0, 28.0,
                      fcNavy(), fcWhite(), fcGreen(), 10.0, 1.5, 10.0, 1);
      ed.selected = ed.count - 1;
      markDirty(&ed);
      selectTool(&ed, ToolKind::ToolMove as int);
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
        if (ed.tool == (ToolKind::ToolFrame as int) || ed.tool == (ToolKind::ToolSection as int)) {
          rw = 320.0;
          rh = 220.0;
        } else if (ed.tool == (ToolKind::ToolLine as int) || ed.tool == (ToolKind::ToolArrow as int)) {
          rw = 180.0;
          rh = 24.0;
        } else if (ed.tool == (ToolKind::ToolStar as int) || ed.tool == (ToolKind::ToolPolygon as int) || ed.tool == (ToolKind::ToolEllipse as int)) {
          rw = 120.0;
          rh = 120.0;
        } else {
          rw = 180.0;
          rh = 120.0;
        }
      }
      spawnRubberBandShape(&ed, rx0, ry0, rw, rh);
      ed.selected = ed.count - 1;
      markDirty(&ed);
      selectTool(&ed, ToolKind::ToolMove as int);
      refreshInspectorLabels(&ed);
    }
  }

  if (ed.dragging) {
    if (gui::mouseDown()) {
      if (ed.selected >= 0 && ed.selected < ed.count) {
        float ddx = (mx - ed.dragMouseX) / scale;
        float ddy = (my - ed.dragMouseY) / scale;
        float snapTol = 6.0 / gui::maxf(0.2, scale);
        if (ed.dragHandle != (HandleKind::HandleNone as int)) {
          Rect nr = applyResizeDelta(ed.dragStartX, ed.dragStartY, ed.dragStartW, ed.dragStartH,
                                     ed.dragHandle, ddx, ddy, 16.0);
          if (ed.tool == (ToolKind::ToolScale as int) && ed.dragStartW > 1.0 && ed.dragStartH > 1.0) {
            float ratio = ed.dragStartH / ed.dragStartW;
            nr.h = gui::maxf(16.0, nr.w * ratio);
            clearSnapGuides(&ed);
          } else {
            nr = computeSmartSnapResize(&ed, ed.selected, ed.dragHandle, nr, 16.0, snapTol);
          }
          ed.nodes[ed.selected].x = nr.x;
          ed.nodes[ed.selected].y = nr.y;
          ed.nodes[ed.selected].w = nr.w;
          ed.nodes[ed.selected].h = nr.h;
          ed.hoverParentIdx = -1;
        } else {
          float rawX = ed.dragStartX + ddx;
          float rawY = ed.dragStartY + ddy;
          Rect snapped = computeSmartSnapMove(&ed, ed.selected, rawX, rawY, snapTol);
          float stepX = snapped.x - ed.nodes[ed.selected].x;
          float stepY = snapped.y - ed.nodes[ed.selected].y;
          moveNodeSubtree(&ed, ed.selected, stepX, stepY);
          float mdx = mx - ed.dragMouseX;
          float mdy = my - ed.dragMouseY;
          if (mdx * mdx + mdy * mdy >= 9.0) {
            float centerX = ed.nodes[ed.selected].x + ed.nodes[ed.selected].w * 0.5;
            float centerY = ed.nodes[ed.selected].y + ed.nodes[ed.selected].h * 0.5;
            ed.hoverParentIdx = findContainerAtPoint(&ed, centerX, centerY, ed.selected);
          } else {
            ed.hoverParentIdx = -1;
          }
        }
        markDirty(&ed);
        refreshInspectorLabels(&ed);
      }
    } else {
      if (ed.dragHandle == (HandleKind::HandleNone as int) && ed.selected >= 0 && ed.selected < ed.count) {
        bool actuallyMoved = (ed.nodes[ed.selected].x != ed.dragStartX) || (ed.nodes[ed.selected].y != ed.dragStartY);
        if (actuallyMoved) {
          reparentNodeOnCanvasDrop(&ed, ed.selected);
        }
      }
      clearSnapGuides(&ed);
      ed.dragging = false;
      ed.dragHandle = HandleKind::HandleNone as int;
      ed.hoverParentIdx = -1;
    }
  } else {
    clearSnapGuides(&ed);
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
