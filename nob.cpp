
#include "args/args.hpp"

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
    "src/CodeGen.cpp",
    "src/SymbolQuery.cpp",
    "src/LSPServer.cpp",
};

static void build_target(const char* output, const char* main_source) {
  const char* home = getenv("HOME");
  Nob_Cmd cmd = {0};

  nob_cmd_append(&cmd, "g++", "-std=c++20", "-g", "-O0", "-I./include",
                 "-IC:\\msys64\\home\\client\\.local\\include");

  for (size_t i = 0; i < NOB_ARRAY_LEN(compiler_sources); ++i) {
    nob_cmd_append(&cmd, compiler_sources[i]);
  }

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

void build_config(args::Subparser& parser) {
  args::Flag glang(parser, "glang", "Build glang compiler", {"g", "glang"});
  args::Flag test_runner(parser, "test_runner", "Build the test runner",
                         {"t", "tests"});

  parser.Parse();

  if (!nob_mkdir_if_not_exists("build")) {
    return;
  }

  if (!glang && !test_runner) {
    build_target("build/gcli", "src/main.cpp");
    build_target("build/test_runner", "tests/runner.cpp");
    return;
  }

  if (test_runner) {
    build_target("build/test_runner", "tests/runner.cpp");
    return;
  }

  build_target("build/gcli", "src/main.cpp");
}

void run_tests(args::Subparser& parser) {
  parser.Parse();

  Nob_Cmd cmd = {0};
  nob_cmd_append(&cmd, "build/test_runner");

  if (nob_cmd_run(&cmd)) {
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