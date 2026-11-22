# CUI + Glang

This example uses [CUI](https://github.com/yappologistic/CUI), yappatronics'
C99 immediate-mode UI library. CUI 1.4.0 is vendored in `third_party/cui`.

The generated C++ contains no `#include <cui/cui.h>` or `#include <cui/cui_app.h>`.
`std/cui.g` declares every CUI function with `[[extern, c_abi]]` and mirrors the
public C structs and enums on the Glang side. The C library is needed only when
linking the final executable.

## Build the library

From the repository root:

```bat
nob.exe build --cui
```

This compiles the vendored CUI sources and writes the static library to:

```text
build/lib/libcui.a
```

The target is incremental. Pass `-Rebuild` to the example script (or remove
`build/cui/obj` and `build/lib/libcui.a`) to force a full rebuild.

## Build and run an example

`examples/cui/intellij.g` is an IntelliJ IDEA UI mock: native menu bar and
toolbar, project tool window with a tree and search field, document tabs,
breadcrumbs, a syntax-highlighted code editor, a bottom Run/Problems/Terminal/Git
panel, an AI Assistant side panel, and the IDE status bar.

`examples/cui/figcraft.g` is a light FigCraft/ArtCraft-style design tool:
document tab strip, pages and layers panel, a live canvas with a dashboard
frame, a Design/Prototype inspector, and the floating bottom toolbar. Tools,
layers, inspector tabs, and the frame drag are interactive.

```bat
rem Build the CUI library and the IntelliJ mock (the default).
examples\cui\build.cmd

rem Build the FigCraft mock instead.
examples\cui\build.cmd -Figcraft

rem Build only build\lib\libcui.a.
examples\cui\build.cmd -Lib

rem Force a full CUI library rebuild.
examples\cui\build.cmd -Rebuild

rem Build and run three hidden frames; useful as a smoke test.
examples\cui\build.cmd -Figcraft -Smoke

rem Build and open the interactive window.
examples\cui\build.cmd -Figcraft -Run

rem Build and save a screenshot to build\cui\figcraft.png.
examples\cui\build.cmd -Figcraft -Shot
```

`-Intellij` selects the default mock explicitly. Set `CUI_SMOKE=1` directly to
run the hidden three-frame path without the script. With a normal interactive
build, CUI itself also understands `CUI_SCREENSHOT`,
`CUI_SCREENSHOT_FRAMES`, and `CUI_RENDERER=software`.

`examples/cui/hello.g` is a smaller demo of the core controls; it is kept as a
readable first example.

## Link your own Glang program

The short form, using `gcli`'s native build path:

```bat
build\gcli.exe build my_app.g --output build\my_app.exe -L build\lib -l cui -l user32 -l gdi32 -l opengl32 -l shell32 -l imm32 -l dwmapi -l comdlg32 -l ole32
```

Or transpile first and link with `g++`:

```bat
build\gcli.exe build my_app.g --cpp -o build\my_app.cpp
g++ -std=c++26 build\my_app.cpp build\lib\libcui.a -o build\my_app.exe -luser32 -lgdi32 -lopengl32 -lshell32 -limm32 -ldwmapi -lcomdlg32 -lole32
```

No CUI include directory is passed to the generated C++ compile. The CUI
library and the Win32 system libraries are link-time dependencies only.

## Binding shape

```glang
import std.cui;

CuiAppDesc desc = std::cui::appDesc("My app", 640, 480);
CuiApp app = cui_app_create(&desc);
if (app == nullptr) return 1;
defer cui_app_destroy(app);

while (cui_app_frame(app)) {
  CuiCtx ui = cui_app_ui(app);
  CuiBox page = CuiBox{pad: 24.0, gap: 12.0, width: std::cui::fill()};
  cui_column_begin(ui, &page);
  cui_heading(ui, "Hello", 2);
  CuiButtonOpts button = CuiButtonOpts{variant: CuiButtonVariant::ButtonPrimary};
  if (cui_button_ex(ui, "Click me", &button)) {
    // ...
  }
  cui_box_end(ui);
}
```

CUI's named-argument macros are C designated initializers, so the binding calls
the underlying `_ex` functions with an explicit option struct. A zero-initialized
option struct is CUI's default; set only the fields you need. `std::cui` adds
helpers for sizes (`fit`, `grow`, `fill`, `px`, `pct`), colors (`rgb`, `rgba`,
`tokenColor`), and app descriptions (`appDesc`).

The binding covers the app/window layer, layout containers, scrolling and split
panes, text, buttons, selection controls, text inputs/selects, badges, progress,
toasts, tabs, alerts, the menu bar and dropdown menus, toolbar and tool options,
status bar, document tabs, navigation items and breadcrumbs, tree/list/tab bar,
popovers, avatars, empty states, the command palette, the code editor, charts
and sparklines, and the Lucide icon helpers under `std::cui::icons`. It is a
curated subset of CUI 1.4.0, not every widget. To expose more, mirror the option
struct's field order and types exactly and add an `[[extern, c_abi]]`
declaration for the matching `_ex` function.

`tests/87_cui_bindings.g` checks the mirrored structs and helpers without
linking CUI.
