
#if defined(_WIN32) || defined(_WIN64)
    #include <windows.h>
    #include <lmcons.h>
#endif

#include "args/args.hpp"

#include <algorithm>
#include <filesystem>
#include <string>
#include <vector>

// nob.cpp includes headers from include/, so the self-rebuild command needs
// the include path and the same C++ standard as the compiler build.
#define NOB_REBUILD_URSELF(binary_path, source_path) \
    "g++", "-std=c++20", "-I./include", "-o", binary_path, source_path


#define NOB_IMPLEMENTATION
#include "nob.h"

static const char *compiler_sources[] = {
    "src/Token.cpp",
    "src/Lexer.cpp",
    "src/AST.cpp",
    "src/Parser.cpp",
    "src/Type.cpp",
    "src/SymbolTable.cpp",
    "src/TypeChecker.cpp",
    "src/CppCodeGen.cpp",
    "src/SymbolQuery.cpp",
    "src/LSPServer.cpp",
};

// Vendored CUI 1.4.0 sources, mirroring CUI_CORE_SOURCES in
// third_party/cui/CMakeLists.txt plus the embedded fonts.
static const char *cui_core_sources[] = {
    "src/cui_core.c",
    "src/cui_theme.c",
    "src/cui_draw.c",
    "src/cui_text.c",
    "src/cui_layout.c",
    "src/cui_widgets.c",
    "src/cui_controls.c",
    "src/cui_textedit.c",
    "src/cui_overlay.c",
    "src/cui_data.c",
    "src/cui_charts.c",
    "src/cui_extras.c",
    "src/cui_actions.c",
    "src/cui_pickers.c",
    "src/cui_disclosure.c",
    "src/cui_loading.c",
    "src/cui_grid.c",
    "src/cui_treetable.c",
    "src/cui_code.c",
    "src/cui_markdown.c",
    "src/cui_editor.c",
    "src/cui_diff.c",
    "src/cui_tools.c",
    "src/cui_hex.c",
    "src/cui_social.c",
    "src/cui_media.c",
    "src/cui_planning.c",
    "src/cui_chrome.c",
    "src/cui_dock.c",
    "src/cui_viz.c",
    "src/cui_motion.c",
    "src/cui_ai.c",
    "src/cui_voice.c",
    "src/cui_image.c",
    "src/cui_nodes.c",
    "src/cui_flame.c",
    "src/cui_curves.c",
    "src/cui_timeline.c",
    "src/cui_dials.c",
    "src/cui_month.c",
    "src/cui_strings.c",
    "src/cui_devtools.c",
    "src/cui_graph.c",
    "src/cui_devpanels.c",
    "src/cui_regex.c",
    "src/cui_devviews.c",
    "src/cui_instrument.c",
    "src/cui_canvas.c",
    "src/cui_tour.c",
    "src/cui_photo.c",
    "src/cui_creative.c",
    "src/cui_files.c",
    "src/cui_terminal.c",
    "src/cui_emoji.c",
    "src/render/cui_render_sw.c",
    "src/render/cui_render_gl.c",
    "src/cui_font_data.c",
    "src/cui_inflate.c",
};

#if defined(_WIN32) || defined(_WIN64)
std::string getCurrentUsername() {
    wchar_t buffer[UNLEN + 1];
    DWORD size = UNLEN + 1;
    if (GetUserNameW(buffer, &size)) {
        // Convert Windows wide string (UTF-16) to standard UTF-8 string
        std::wstring wstr(buffer);
        return std::string(wstr.begin(), wstr.end());
    }
    return "Unknown";
}
#endif



static void build_target(const char* output, const char* main_source) {
  const char* home = getenv("HOME");
  Nob_Cmd cmd = {0};

#if defined(_WIN32) || defined(_WIN64)
  std::string username = getCurrentUsername();
  std::string includes =  "-IC:\\msys64\\home\\" + username + "\\.local\\include";
  std::string libs =  "-LC:\\msys64\\home\\" + username + "\\.local\\lib";
#else
  std::string includes = "-I" + std::string(home) + "./local/include";
  std::string libs = "-L" + std::string(home) + "./local/lib";
#endif

  nob_cmd_append(&cmd, "g++", "-std=c++20", "-ggdb", "-O0", "-I./include",
                 includes.c_str());

  for (size_t i = 0; i < NOB_ARRAY_LEN(compiler_sources); ++i) {
    nob_cmd_append(&cmd, compiler_sources[i]);
  }

  nob_cmd_append(&cmd, main_source);

  nob_cmd_append(&cmd, "-o", output);

  nob_cmd_append(&cmd, libs.c_str());

#ifdef _WIN32
    nob_cmd_append(&cmd, "-D_WIN32_WINNT=0x0A00", "-DWINVER=0x0A00", "-lws2_32",
                   "-lcrypt32");
#else
    nob_cmd_append(&cmd, "-pthread");
#endif
    nob_cmd_append(&cmd, "-llsp");

    if (!nob_cmd_run_sync_and_reset(&cmd)) {
        nob_log(NOB_ERROR, "Failed to build %s", output);
        exit(1);
    }
}

static void simple_build(const char* output, const char* main_source) {
  const char* home = getenv("HOME");
  Nob_Cmd cmd = {0};

  nob_cmd_append(&cmd, "g++", "-std=c++20", "-g", "-O0", "-I./include",
                 "-IC:\\msys64\\home\\client\\.local\\include");

  nob_cmd_append(&cmd, main_source);

  nob_cmd_append(&cmd, "-o", output);

  nob_cmd_append(&cmd, "-LC:\\msys64\\home\\client\\.local\\lib");

#ifdef _WIN32
  nob_cmd_append(&cmd, "-D_WIN32_WINNT=0x0A00", "-DWINVER=0x0A00", "-lws2_32",
                 "-lcrypt32");
#else
  nob_cmd_append(&cmd, "-pthread");
#endif
  nob_cmd_append(&cmd, "-llsp");

  if (!nob_cmd_run_sync_and_reset(&cmd)) {
    nob_log(NOB_ERROR, "Failed to build %s", output);
    exit(1);
  }
}

static void build_cui_library() {
  namespace fs = std::filesystem;

  const fs::path root = "third_party/cui";
  const fs::path objectDir = "build/cui/obj";
  const fs::path libDir = "build/lib";
  const fs::path lib = libDir / "libcui.a";
  const std::string libString = lib.string();
  const std::string includeDir = (root / "include").string();
  const std::string thirdPartyDir = (root / "third_party").string();

  std::error_code error;
  fs::create_directories(objectDir, error);
  if (error) {
    nob_log(NOB_ERROR, "Could not create %s: %s", objectDir.string().c_str(),
            error.message().c_str());
    exit(1);
  }
  fs::create_directories(libDir, error);
  if (error) {
    nob_log(NOB_ERROR, "Could not create %s: %s", libDir.string().c_str(),
            error.message().c_str());
    exit(1);
  }

  std::vector<fs::path> sources;
  for (const char* source : cui_core_sources) {
    sources.push_back(root / source);
  }

#if defined(_WIN32) || defined(_WIN64)
  sources.push_back(root / "src/platform/cui_app.c");
  sources.push_back(root / "src/platform/cui_dialogs.c");
  sources.push_back(root / "src/platform/cui_app_win32.c");
#elif defined(__APPLE__)
  nob_log(NOB_ERROR,
          "The vendored CUI Cocoa backend is not built by this target; use "
          "CUI's CMake project on macOS.");
  exit(1);
#else
  sources.push_back(root / "src/platform/cui_app.c");
  sources.push_back(root / "src/platform/cui_dialogs.c");
  sources.push_back(root / "src/platform/cui_app_x11.c");
#endif

  bool compiledAny = false;
  std::vector<std::string> objectStrings;

  for (const auto& source : sources) {
    if (!fs::exists(source)) {
      nob_log(NOB_ERROR, "CUI source is missing: %s", source.string().c_str());
      exit(1);
    }

    std::string relative = source.lexically_relative(root).generic_string();
    std::replace(relative.begin(), relative.end(), '/', '_');
    if (relative.size() > 2 &&
        relative.compare(relative.size() - 2, 2, ".c") == 0) {
      relative.resize(relative.size() - 2);
    }

    const fs::path object = objectDir / (relative + ".o");
    const std::string objectString = object.string();

    bool needsCompile = !fs::exists(object, error);
    error.clear();
    if (!needsCompile) {
      auto sourceTime = fs::last_write_time(source, error);
      if (error) {
        error.clear();
        needsCompile = true;
      } else {
        auto objectTime = fs::last_write_time(object, error);
        if (error) {
          error.clear();
          needsCompile = true;
        } else {
          needsCompile = sourceTime > objectTime;
        }
      }
    }

    if (needsCompile) {
      const std::string sourceString = source.string();
      Nob_Cmd cmd = {0};
      nob_cmd_append(&cmd, "gcc", "-std=c99", "-O2", "-ffunction-sections",
                     "-fdata-sections", "-I", includeDir.c_str(), "-I",
                     thirdPartyDir.c_str(), "-c", sourceString.c_str(), "-o",
                     objectString.c_str());
      if (!nob_cmd_run_sync_and_reset(&cmd)) {
        nob_log(NOB_ERROR, "Failed to compile %s", sourceString.c_str());
        exit(1);
      }
      compiledAny = true;
    }

    objectStrings.push_back(objectString);
  }

  if (compiledAny || !fs::exists(lib, error)) {
    if (compiledAny) {
      fs::remove(lib, error);
      error.clear();
    }
    Nob_Cmd cmd = {0};
    nob_cmd_append(&cmd, "ar", "rcs", libString.c_str());
    for (const auto& object : objectStrings) {
      nob_cmd_append(&cmd, object.c_str());
    }
    if (!nob_cmd_run_sync_and_reset(&cmd)) {
      nob_log(NOB_ERROR, "Failed to archive %s", libString.c_str());
      exit(1);
    }
  }

  nob_log(NOB_INFO, "CUI static library: %s", libString.c_str());
}

void build_config(args::Subparser& parser) {
  args::Flag glang(parser, "glang", "Build glang compiler", {"g", "glang"});
  args::Flag test_runner(parser, "test_runner", "Build the test runner",
                         {"t", "tests"});
  args::Flag cui(parser, "cui", "Build the vendored CUI static library",
                 {"cui"});

  args::Flag changelog(parser, "changelog", "Build build the CHNAGELOG parser",
                       {"c", "changelog"});
  args::Flag examples(parser, "examples", "Build examples serializer",
                      {"e", "examples"});

  parser.Parse();

  if (!nob_mkdir_if_not_exists("build")) {
    return;
  }

  if (cui) {
    build_cui_library();
    return;
  }

  if (changelog || examples) {
    if (!nob_mkdir_if_not_exists("tools")) {
      return;
    }
  }

  if (changelog) {
    simple_build("build/changelog", "tools/changelog.cpp");
    return;
  }

  if (examples) {
    simple_build("build/examples", "tools/examples.cpp");
    return;
  }

  if (!glang && !test_runner) {
    build_target("build/gcli", "src/main.cpp");
    build_target("build/test_runner", "tools/test-runner.cpp");
    return;
  }

  if (test_runner) {
    build_target("build/test_runner", "tools/test-runner.cpp");
    return;
  }

  build_target("build/gcli", "src/main.cpp");
}

void run_tests(args::Subparser& parser) {
  parser.Parse();

  Nob_Cmd cmd = {0};
#if defined(_WIN32) || defined(_WIN64)
  nob_cmd_append(&cmd, "build/test_runner.exe");
#else
  nob_cmd_append(&cmd, "build/test_runner");
#endif

  if (!nob_cmd_run(&cmd)) {
    nob_log(NOB_ERROR, "Failed to run tests");
    return;
  }
}

int main(int argc, char **argv)
{
    NOB_GO_REBUILD_URSELF(argc, argv);

    args::ArgumentParser parser("Glang Build System",
                                "The build system for the glang compiler");

    args::Group commands(parser, "commands");

    args::Command build_command(
        commands, "build", "Build the project or source file.", &build_config);

    args::Command test_command(commands, "test", "Run the test.", &run_tests);

    args::HelpFlag help(parser, "HELP", "Display this help menu.",
                        {'h', "help"});

    try {
      parser.ParseCLI(argc, argv);
    } catch (const args::Help&) {
      std::cout << parser;
      return 0;
    } catch (const args::Error& e) {
      std::cerr << "error: " << e.what() << '\n';

      std::cerr << parser;

      return 1;
    }

    /*
     */

    nob_log(NOB_INFO, "Build successful");

    return 0;
}