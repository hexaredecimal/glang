@echo off
setlocal EnableExtensions

rem Build the vendored CUI static library and the Glang CUI example.
rem
rem   examples\cui\build.cmd              build the library and the IntelliJ mock
rem   examples\cui\build.cmd -Figcraft    build the FigCraft design-tool mock
rem   examples\cui\build.cmd -Intellij    build the IntelliJ mock (default)
rem   examples\cui\build.cmd -Lib         build only build\lib\libcui.a
rem   examples\cui\build.cmd -Rebuild     force a CUI library rebuild
rem   examples\cui\build.cmd -Smoke       run a hidden three-frame check
rem   examples\cui\build.cmd -Run         open the interactive window
rem   examples\cui\build.cmd -Shot        save build\cui\<example>.png and exit
rem
rem Requires gcc, g++, ar, and gcli.exe. MSYS2's mingw64\bin should be on PATH.

set "ROOT=%~dp0..\.."
pushd "%ROOT%" >nul
if errorlevel 1 (
  echo Could not enter the repository root.
  exit /b 1
)

set "TARGET=intellij"
set "LIB_ONLY="
set "REBUILD="
set "SMOKE="
set "RUN="
set "SHOT="

:parse
if "%~1"=="" goto parsed
if /I "%~1"=="-Figcraft" (
  set "TARGET=figcraft"
) else if /I "%~1"=="-Builder" (
  set "TARGET=figcraft_builder"
) else if /I "%~1"=="-FigcraftBuilder" (
  set "TARGET=figcraft_builder"
) else if /I "%~1"=="-Intellij" (
  set "TARGET=intellij"
) else if /I "%~1"=="-Lib" (
  set "LIB_ONLY=1"
) else if /I "%~1"=="-Library" (
  set "LIB_ONLY=1"
) else if /I "%~1"=="-Rebuild" (
  set "REBUILD=1"
) else if /I "%~1"=="-Smoke" (
  set "SMOKE=1"
) else if /I "%~1"=="-Run" (
  set "RUN=1"
) else if /I "%~1"=="-Shot" (
  set "SHOT=1"
) else (
  echo Unknown option: %~1
  echo Usage: examples\cui\build.cmd [-Figcraft^|-Intellij] [-Lib] [-Rebuild] [-Smoke] [-Run] [-Shot]
  popd
  exit /b 2
)
shift
goto parse

:parsed

where gcc >nul 2>nul
if errorlevel 1 (
  echo gcc was not found on PATH. Add MSYS2's mingw64\bin to PATH.
  popd
  exit /b 1
)
where g++ >nul 2>nul
if errorlevel 1 (
  echo g++ was not found on PATH. Add MSYS2's mingw64\bin to PATH.
  popd
  exit /b 1
)
where ar >nul 2>nul
if errorlevel 1 (
  echo ar was not found on PATH. Add MSYS2's mingw64\bin to PATH.
  popd
  exit /b 1
)

if not exist "nob.exe" (
  echo nob.exe was not found. Build the build system bootstrap first.
  popd
  exit /b 1
)

if defined REBUILD (
  if exist "build\lib\libcui.a" del /q "build\lib\libcui.a"
  if exist "build\cui\obj" rmdir /s /q "build\cui\obj"
)

nob.exe build --cui
if errorlevel 1 (
  echo CUI library build failed.
  popd
  exit /b 1
)

if defined LIB_ONLY (
  echo CUI static library: build\lib\libcui.a
  popd
  exit /b 0
)

if not exist "build\gcli.exe" (
  echo build\gcli.exe was not found. Build it first with: nob.exe build --glang
  popd
  exit /b 1
)

if not exist "build\cui" mkdir "build\cui"

build\gcli.exe build "examples\cui\%TARGET%.g" --cpp -o "build\cui\%TARGET%.cpp"
if errorlevel 1 (
  echo Glang transpilation failed.
  popd
  exit /b 1
)

g++ -std=c++26 -O1 "build\cui\%TARGET%.cpp" "build\lib\libcui.a" -o "build\cui\%TARGET%.exe" -luser32 -lgdi32 -lopengl32 -lshell32 -limm32 -ldwmapi -lcomdlg32 -lole32
if errorlevel 1 (
  echo C++ compilation or linking failed.
  popd
  exit /b 1
)

echo Built build\cui\%TARGET%.exe

if defined SMOKE (
  set "CUI_SMOKE=1"
  "build\cui\%TARGET%.exe"
  if errorlevel 1 (
    echo The CUI smoke run failed.
    popd
    exit /b 1
  )
  set "CUI_SMOKE="
  echo CUI smoke run passed.
) else if defined SHOT (
  set "CUI_SCREENSHOT=build\cui\%TARGET%.png"
  set "CUI_SCREENSHOT_FRAMES=4"
  set "CUI_RENDERER=software"
  "build\cui\%TARGET%.exe"
  if errorlevel 1 (
    echo The CUI screenshot run failed.
    popd
    exit /b 1
  )
  set "CUI_SCREENSHOT="
  set "CUI_SCREENSHOT_FRAMES="
  set "CUI_RENDERER="
  echo Saved build\cui\%TARGET%.png
) else if defined RUN (
  "build\cui\%TARGET%.exe"
  if errorlevel 1 (
    echo The CUI example failed.
    popd
    exit /b 1
  )
)

popd
exit /b 0
