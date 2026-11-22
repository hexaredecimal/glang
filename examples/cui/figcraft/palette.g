// FigCraft UI3 Palette and String/Color Formatting Utilities.
// Supports both Light and Dark themes with crisp contrast and zero allocations.

import std.gui;

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
// Zero-allocation string utilities
// ---------------------------------------------------------------------------

int strLen(const char* s) {
  if (s == nullptr) { return 0; }
  int i = 0;
  while (s[i] != '\0') {
    i = i + 1;
  }
  return i;
}

void copyStr(char* dst, const char* src, int cap) {
  if (dst == nullptr || cap <= 0) { return; }
  if (src == nullptr) {
    dst[0] = '\0';
    return;
  }
  int i = 0;
  while (src[i] != '\0' && i < cap - 1) {
    dst[i] = src[i];
    i = i + 1;
  }
  dst[i] = '\0';
}

void appendStr(char* dst, const char* src, int cap) {
  if (dst == nullptr || src == nullptr || cap <= 0) { return; }
  int len = strLen(dst);
  int i = 0;
  while (src[i] != '\0' && len + i < cap - 1) {
    dst[len + i] = src[i];
    i = i + 1;
  }
  dst[len + i] = '\0';
}

bool strEquals(const char* a, const char* b) {
  if (a == nullptr || b == nullptr) { return a == b; }
  int i = 0;
  while (a[i] != '\0' && b[i] != '\0') {
    if (a[i] != b[i]) { return false; }
    i = i + 1;
  }
  return a[i] == b[i];
}

char toLowerAscii(char c) {
  if (c >= 'A' && c <= 'Z') {
    return ((c as int) + 32) as char;
  }
  return c;
}

bool strContainsFold(const char* haystack, const char* needle) {
  if (needle == nullptr || needle[0] == '\0') { return true; }
  if (haystack == nullptr) { return false; }
  int nLen = strLen(needle);
  int hLen = strLen(haystack);
  if (nLen > hLen) { return false; }
  for (int i = 0; i <= hLen - nLen; i = i + 1) {
    bool ok = true;
    for (int j = 0; j < nLen; j = j + 1) {
      if (toLowerAscii(haystack[i + j]) != toLowerAscii(needle[j])) {
        ok = false;
        break;
      }
    }
    if (ok) { return true; }
  }
  return false;
}

void formatInt(char* dst, int value, int cap) {
  if (dst == nullptr || cap <= 1) { return; }
  int pos = 0;
  if (value < 0) {
    dst[pos] = '-';
    pos = pos + 1;
    value = -value;
  }
  char[16] digits;
  int d = 0;
  if (value == 0) {
    digits[0] = '0';
    d = 1;
  } else {
    while (value > 0 && d < 15) {
      digits[d] = (48 + (value % 10)) as char;
      value = value / 10;
      d = d + 1;
    }
  }
  while (d > 0 && pos < cap - 1) {
    d = d - 1;
    dst[pos] = digits[d];
    pos = pos + 1;
  }
  dst[pos] = '\0';
}

void formatDims(char* dst, int w, int h, int cap) {
  if (dst == nullptr || cap < 8) { return; }
  formatInt(dst, w, cap);
  appendStr(dst, " x ", cap);
  char[16] hBuf;
  formatInt(&hBuf[0], h, 16);
  appendStr(dst, &hBuf[0], cap);
}

void formatPercent(char* dst, float ratio, int cap) {
  int pct = ((ratio * 100.0) + 0.5) as int;
  formatInt(dst, pct, cap);
  appendStr(dst, "%", cap);
}

void formatDegree(char* dst, float deg, int cap) {
  int v = deg as int;
  formatInt(dst, v, cap);
  appendStr(dst, " deg", cap);
}

char hexDigit(int nibble) {
  int n = nibble % 16;
  if (n < 0) { n = 0; }
  if (n < 10) { return (48 + n) as char; }
  return (65 + (n - 10)) as char;
}

void formatHexColor(char* dst, Color c, int cap) {
  if (dst == nullptr || cap < 7) { return; }
  int r = c.r as int;
  int g = c.g as int;
  int b = c.b as int;
  dst[0] = hexDigit(r / 16);
  dst[1] = hexDigit(r % 16);
  dst[2] = hexDigit(g / 16);
  dst[3] = hexDigit(g % 16);
  dst[4] = hexDigit(b / 16);
  dst[5] = hexDigit(b % 16);
  dst[6] = '\0';
}
