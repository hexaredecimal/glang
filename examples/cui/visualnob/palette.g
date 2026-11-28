// VisualNob Theme Palette, Pin/Category Colors, and Zero-Allocation String Helpers.
// Matches FigCraft UI3 visual polish in both Light and Dark themes.

import std.gui;

// ---------------------------------------------------------------------------
// Workspace surfaces & typography colors
// ---------------------------------------------------------------------------

Color vnChrome(bool dark) {
  if (dark) { return gui::rgb(26, 27, 31); }
  return gui::rgb(240, 241, 244);
}

Color vnPanel(bool dark) {
  if (dark) { return gui::rgb(37, 38, 43); }
  return gui::rgb(252, 252, 253);
}

Color vnCard(bool dark) {
  if (dark) { return gui::rgb(46, 48, 55); }
  return gui::rgb(255, 255, 255);
}

Color vnCardRaised(bool dark) {
  if (dark) { return gui::rgb(54, 56, 65); }
  return gui::rgb(248, 249, 251);
}

Color vnCanvasBg(bool dark) {
  if (dark) { return gui::rgb(21, 22, 26); }
  return gui::rgb(233, 236, 241);
}

Color vnGridMinor(bool dark) {
  if (dark) { return gui::rgba(255, 255, 255, 11); }
  return gui::rgba(15, 23, 38, 13);
}

Color vnGridMajor(bool dark) {
  if (dark) { return gui::rgba(255, 255, 255, 22); }
  return gui::rgba(15, 23, 38, 24);
}

Color vnGridDot(bool dark) {
  if (dark) { return gui::rgba(255, 255, 255, 34); }
  return gui::rgba(15, 23, 38, 32);
}

Color vnBorder(bool dark) {
  if (dark) { return gui::rgb(68, 71, 80); }
  return gui::rgb(218, 222, 229);
}

Color vnDivider(bool dark) {
  if (dark) { return gui::rgb(56, 58, 66); }
  return gui::rgb(228, 231, 237);
}

Color vnField(bool dark) {
  if (dark) { return gui::rgb(58, 60, 68); }
  return gui::rgb(243, 245, 248);
}

Color vnHover(bool dark) {
  if (dark) { return gui::rgb(66, 69, 79); }
  return gui::rgb(236, 239, 244);
}

Color vnText(bool dark) {
  if (dark) { return gui::rgb(240, 242, 246); }
  return gui::rgb(24, 26, 32);
}

Color vnSecondaryText(bool dark) {
  if (dark) { return gui::rgb(174, 178, 190); }
  return gui::rgb(96, 102, 114);
}

Color vnMutedText(bool dark) {
  if (dark) { return gui::rgb(122, 127, 140); }
  return gui::rgb(144, 150, 162);
}

// ---------------------------------------------------------------------------
// Brand & semantic colors
// ---------------------------------------------------------------------------

Color vnWhite() => gui::rgb(255, 255, 255);
Color vnNavy() => gui::rgb(16, 24, 40);
Color vnMint() => gui::rgb(10, 207, 131);
Color vnMintDark() => gui::rgb(5, 134, 86);

Color vnMintSoft(bool dark) {
  if (dark) { return gui::rgb(18, 64, 48); }
  return gui::rgb(220, 248, 235);
}

Color vnBlue() => gui::rgb(59, 130, 246);
Color vnBlueSoft(bool dark) {
  if (dark) { return gui::rgb(30, 52, 86); }
  return gui::rgb(224, 237, 255);
}

Color vnViolet() => gui::rgb(139, 92, 246);
Color vnVioletSoft(bool dark) {
  if (dark) { return gui::rgb(52, 38, 86); }
  return gui::rgb(241, 234, 255);
}

Color vnAmber() => gui::rgb(234, 152, 34);
Color vnAmberSoft(bool dark) {
  if (dark) { return gui::rgb(78, 54, 22); }
  return gui::rgb(254, 243, 218);
}

Color vnCoral() => gui::rgb(235, 78, 88);
Color vnCoralSoft(bool dark) {
  if (dark) { return gui::rgb(84, 34, 40); }
  return gui::rgb(254, 228, 231);
}

Color vnCyan() => gui::rgb(14, 165, 203);
Color vnCyanSoft(bool dark) {
  if (dark) { return gui::rgb(24, 62, 78); }
  return gui::rgb(222, 246, 252);
}

Color vnNodeShadow(bool dark) {
  if (dark) { return gui::rgba(0, 0, 0, 110); }
  return gui::rgba(16, 24, 40, 26);
}

// ---------------------------------------------------------------------------
// Selection helpers (Glang has no ?: ternary operator)
// ---------------------------------------------------------------------------

Color vnPickColor(bool cond, Color yes, Color no) {
  if (cond) { return yes; }
  return no;
}

float vnPickFloat(bool cond, float yes, float no) {
  if (cond) { return yes; }
  return no;
}

int vnPickInt(bool cond, int yes, int no) {
  if (cond) { return yes; }
  return no;
}

const char* vnPickText(bool cond, const char* yes, const char* no) {
  if (cond) { return yes; }
  return no;
}

// ---------------------------------------------------------------------------
// Zero-allocation string & number formatting utilities
// ---------------------------------------------------------------------------

int vnStrLen(const char* s) {
  if (s == nullptr) { return 0; }
  int i = 0;
  while (s[i] != '\0') {
    i = i + 1;
  }
  return i;
}

void vnCopyStr(char* dst, const char* src, int cap) {
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

void vnAppendStr(char* dst, const char* src, int cap) {
  if (dst == nullptr || src == nullptr || cap <= 0) { return; }
  int len = vnStrLen(dst);
  int i = 0;
  while (src[i] != '\0' && len + i < cap - 1) {
    dst[len + i] = src[i];
    i = i + 1;
  }
  dst[len + i] = '\0';
}

bool vnStrEquals(const char* a, const char* b) {
  if (a == nullptr || b == nullptr) { return a == b; }
  int i = 0;
  while (a[i] != '\0' && b[i] != '\0') {
    if (a[i] != b[i]) { return false; }
    i = i + 1;
  }
  return a[i] == b[i];
}

char vnToLower(char c) {
  if (c >= 'A' && c <= 'Z') {
    return ((c as int) + 32) as char;
  }
  return c;
}

bool vnContainsFold(const char* haystack, const char* needle) {
  if (needle == nullptr || needle[0] == '\0') { return true; }
  if (haystack == nullptr) { return false; }
  int nLen = vnStrLen(needle);
  int hLen = vnStrLen(haystack);
  if (nLen > hLen) { return false; }
  for (int i = 0; i <= hLen - nLen; i = i + 1) {
    bool ok = true;
    for (int j = 0; j < nLen; j = j + 1) {
      if (vnToLower(haystack[i + j]) != vnToLower(needle[j])) {
        ok = false;
        break;
      }
    }
    if (ok) { return true; }
  }
  return false;
}

void vnFormatInt(char* dst, int value, int cap) {
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

void vnFormatNum(char* dst, float value, int cap) {
  if (dst == nullptr || cap <= 1) { return; }
  if (value < 0.0005 && value > -0.0005) {
    vnCopyStr(dst, "0", cap);
    return;
  }
  bool neg = value < 0.0;
  float av = if (neg) -value else value;
  int scaled = ((av * 100.0) + 0.5) as int;
  int whole = scaled / 100;
  int frac = scaled % 100;

  dst[0] = '\0';
  if (neg) {
    vnCopyStr(dst, "-", cap);
  }
  char[20] wbuf;
  vnFormatInt(&wbuf[0], whole, 20);
  vnAppendStr(dst, &wbuf[0], cap);

  if (frac > 0) {
    vnAppendStr(dst, ".", cap);
    int tens = frac / 10;
    int ones = frac % 10;
    char[4] fbuf;
    fbuf[0] = (48 + tens) as char;
    if (ones > 0) {
      fbuf[1] = (48 + ones) as char;
      fbuf[2] = '\0';
    } else {
      fbuf[1] = '\0';
    }
    vnAppendStr(dst, &fbuf[0], cap);
  }
}

void vnFormatPercent(char* dst, float ratio, int cap) {
  int pct = ((ratio * 100.0) + 0.5) as int;
  vnFormatInt(dst, pct, cap);
  vnAppendStr(dst, "%", cap);
}
