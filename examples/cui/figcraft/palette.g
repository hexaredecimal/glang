// FigCraft UI3 Palette and String/Color Formatting Utilities.
// Supports both Light and Dark themes with crisp contrast and zero allocations.

import std.gui;
import std.string;
import std.encoding.hex;
import std.math;

// ---------------------------------------------------------------------------
// Theme-aware UI3 Palette
// ---------------------------------------------------------------------------

Color fcChrome(bool dark) {
  if (dark) { return gui::rgb(30, 31, 34); }
  return gui::rgb(239, 239, 239);
}

Color fcPanel(bool dark) {
  if (dark) { return gui::rgb(44, 44, 46); }
  return gui::rgb(252, 252, 252);
}

Color fcCard(bool dark) {
  if (dark) { return gui::rgb(52, 53, 58); }
  return gui::rgb(255, 255, 255);
}

Color fcCanvas(bool dark) {
  if (dark) { return gui::rgb(24, 25, 28); }
  return gui::rgb(238, 238, 238);
}

Color fcCanvasDot(bool dark) {
  if (dark) { return gui::rgba(255, 255, 255, 22); }
  return gui::rgba(0, 0, 0, 22);
}

Color fcBorder(bool dark) {
  if (dark) { return gui::rgb(72, 74, 80); }
  return gui::rgb(226, 226, 226);
}

Color fcDivider(bool dark) {
  if (dark) { return gui::rgb(63, 65, 71); }
  return gui::rgb(234, 234, 234);
}

Color fcText(bool dark) {
  if (dark) { return gui::rgb(242, 243, 245); }
  return gui::rgb(28, 28, 30);
}

Color fcSecondaryText(bool dark) {
  if (dark) { return gui::rgb(176, 179, 188); }
  return gui::rgb(105, 105, 110);
}

Color fcMutedText(bool dark) {
  if (dark) { return gui::rgb(128, 132, 142); }
  return gui::rgb(150, 150, 155);
}

Color fcField(bool dark) {
  if (dark) { return gui::rgb(64, 66, 72); }
  return gui::rgb(245, 245, 246);
}

Color fcPageSelected(bool dark) {
  if (dark) { return gui::rgb(62, 65, 72); }
  return gui::rgb(240, 240, 241);
}

Color fcGreen() => gui::rgb(10, 207, 131);
Color fcGreenDark() => gui::rgb(5, 134, 86);

Color fcGreenSoft(bool dark) {
  if (dark) { return gui::rgb(20, 62, 48); }
  return gui::rgb(219, 247, 234);
}

Color fcGreenBorder(bool dark) {
  if (dark) { return gui::rgb(35, 112, 84); }
  return gui::rgb(150, 230, 197);
}

Color fcPurple() => gui::rgb(124, 77, 255);

Color fcPurpleSoft(bool dark) {
  if (dark) { return gui::rgb(52, 40, 84); }
  return gui::rgb(240, 235, 255);
}

Color fcNavy() => gui::rgb(15, 23, 38);
Color fcNavyRaised() => gui::rgb(27, 39, 59);

Color fcDesignBg(bool dark) {
  if (dark) { return gui::rgb(243, 245, 248); }
  return gui::rgb(243, 245, 248);
}

Color fcDesignBorder() => gui::rgb(231, 234, 239);
Color fcChartGreen() => gui::rgb(16, 163, 127);
Color fcChartMint() => gui::rgb(178, 235, 215);
Color fcChartBlue() => gui::rgb(59, 130, 246);
Color fcWarning() => gui::rgb(217, 145, 38);

Color fcWarningSoft(bool dark) {
  if (dark) { return gui::rgb(78, 57, 26); }
  return gui::rgb(253, 243, 219);
}

Color fcDanger() => gui::rgb(226, 84, 84);

Color fcDangerSoft(bool dark) {
  if (dark) { return gui::rgb(82, 34, 34); }
  return gui::rgb(253, 231, 231);
}

Color fcBlueSoft(bool dark) {
  if (dark) { return gui::rgb(32, 54, 88); }
  return gui::rgb(225, 236, 254);
}

Color fcSelectionWash() => gui::rgba(242, 78, 30, 10);
Color fcSelectionGuide() => gui::rgba(242, 78, 30, 32);
Color fcLayoutGuide() => gui::rgba(239, 68, 68, 24);
Color fcSnapLine() => gui::rgb(255, 68, 90);
Color fcSnapCenter() => gui::rgb(255, 40, 88);
Color fcSnapBadgeBg() => gui::rgb(255, 52, 86);
Color fcWhite() => gui::rgb(255, 255, 255);
Color fcTitleMuted() => gui::rgb(139, 139, 145);

// ---------------------------------------------------------------------------
// Selection helpers (Glang has no ?: operator)
// ---------------------------------------------------------------------------

Color pickColor(bool cond, Color yes, Color no) {
  if (cond) { return yes; }
  return no;
}

float pickFloat(bool cond, float yes, float no) {
  if (cond) { return yes; }
  return no;
}

const char* pickText(bool cond, const char* yes, const char* no) {
  if (cond) { return yes; }
  return no;
}

// ---------------------------------------------------------------------------
// Stdlib-backed formatting & hex color helpers
// ---------------------------------------------------------------------------

void formatDims(char* dst, int w, int h, int cap) {
  if (dst == nullptr || cap < 8) { return; }
  std::string::format_int(dst, w, cap);
  std::string::append_into(dst, " x ", cap);
  char[16] hBuf;
  std::string::format_int(&hBuf[0], h, 16);
  std::string::append_into(dst, &hBuf[0], cap);
}

void formatPercent(char* dst, float ratio, int cap) {
  int pct = ((ratio * 100.0) + 0.5) as int;
  std::string::format_int(dst, pct, cap);
  std::string::append_into(dst, "%", cap);
}

void formatDegree(char* dst, float deg, int cap) {
  int v = deg as int;
  std::string::format_int(dst, v, cap);
  std::string::append_into(dst, " deg", cap);
}

void formatHexColor(char* dst, Color c, int cap) {
  if (dst == nullptr || cap < 7) { return; }
  int r = c.r as int;
  int g = c.g as int;
  int b = c.b as int;
  dst[0] = hex_digit(r / 16, true);
  dst[1] = hex_digit(r % 16, true);
  dst[2] = hex_digit(g / 16, true);
  dst[3] = hex_digit(g % 16, true);
  dst[4] = hex_digit(b / 16, true);
  dst[5] = hex_digit(b % 16, true);
  dst[6] = '\0';
}

Color parseHexColor(const char* hex, uchar alpha, Color fallback) {
  if (hex == nullptr) { return fallback; }
  int idx = 0;
  if (hex[0] == '#') { idx = 1; }
  int[6] nib;
  for (int i = 0; i < 6; i = i + 1) {
    char ch = hex[idx + i];
    if (ch == '\0') { return fallback; }
    int v = hex_digit_value(ch);
    if (v < 0) { return fallback; }
    nib[i] = v;
  }
  int r = nib[0] * 16 + nib[1];
  int g = nib[2] * 16 + nib[3];
  int b = nib[4] * 16 + nib[5];
  return gui::rgba(r, g, b, alpha as int);
}
