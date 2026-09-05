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

static void build_target(const char *output, const char *main_source)
{
    const char *home = getenv("HOME");

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

int main(int argc, char **argv)
{
    NOB_GO_REBUILD_URSELF(argc, argv);

    if (!nob_mkdir_if_not_exists("build")) {
        return 1;
    }

    build_target(
        "build/gcli",
        "src/main.cpp"
    );

    /*
    build_target(
        "build/glang_tests",
        "tests/test_compiler.cpp"
    );
    */

    nob_log(NOB_INFO, "Build successful");

    return 0;
}