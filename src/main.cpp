#include <filesystem>
#include <fstream>
#include <cstdlib>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "args/args.hpp"
#include "compiler/LSPServer.hpp"
#include "compiler/CppCodeGen.hpp"
#include "compiler/Lexer.hpp"
#include "compiler/Parser.hpp"
#include "compiler/TypeChecker.hpp"

#define LOG_IMPLEMENTATION
// #define LOG_RANG // Enables rang usage and highlights marked text instead
#include <logloc/log.h>

#define NOB_IMPLEMENTATION
#include "../nob.h"



using namespace Glang;

bool write_cpp(const std::string& path, const std::string& source) {
  std::ofstream outFile(path);
  if (!outFile.is_open()) {
    std::cerr << "Error: Failed to write to file: " << path << std::endl;
    return false;
  }

  outFile << source;
  if (!outFile) {
    std::cerr << "Error: Failed while writing file: " << path << std::endl;
    return false;
  }
  return true;
}

std::vector<std::string> get_lines(const std::string& path) {
  std::ifstream file(path);
  std::vector<std::string> lines{};
  if (!file) {
    int line = __builtin_LINE();
    int col = 1;
    logloc::Log msg;
    msg.set_start_info(line, col);
    msg.set_kind("[Error]");
    msg.set_message("Failed to read file: " + path);
    msg.report();
    return lines;
  }

  std::string line;
  while (std::getline(file, line)) {
    lines.push_back(line);
  }
  return lines;
}

bool compile(std::string& filePath, std::string targetOutPath,
             bool printSource) {
  std::string code = "";
  std::ifstream file(filePath);
  if (!file.is_open()) {
    std::cerr << "Error: Could not open file " << filePath << std::endl;
    return false;
  }
  std::stringstream ss;
  ss << file.rdbuf();
  code = ss.str();

  Lexer lexer(filePath, code);
  std::vector<Token> tokens = lexer.tokenize();

  Parser parser(tokens);
  auto ast = parser.parseProgram();

  TypeChecker typeChecker;
  TypeCheckResult checkResult = typeChecker.check(ast);

  CppCodeGen codeGen;
  std::string cppCode;

  bool hasErrors =
      lexer.hasErrors() || parser.hasErrors() || checkResult.hasErrors();

  if (!hasErrors && ast) {
    cppCode = codeGen.generate(checkResult.astNodesToCodeGen, ast->topStatements);
    if (codeGen.hasErrors()) {
      hasErrors = true;
    }
  }


  if (hasErrors) {

    for (const auto& err : lexer.errors()) {
      logloc::Log msg;
      msg.set_filename(err.filename);
      msg.set_message(err.message);
      msg.set_input_lines(get_lines(err.filename));
      msg.set_start_info(err.line, err.column); 
      msg.set_end_info(err.line, err.column + err.token.size());
      msg.set_kind("Lexer Error"); 
      msg.reveal_lines_after(3);
      msg.report();
    }
    for (const auto& err : parser.errors()) {
      logloc::Log msg;
      msg.set_filename(err.filename);
      msg.set_message(err.message);
      msg.set_input_lines(get_lines(err.filename));
      msg.set_start_info(err.line, err.column); 
      msg.set_end_info(err.line, err.column + err.token.size());
      msg.set_kind("Parse Error"); 
      msg.reveal_lines_after(3);
      msg.report();
    }
    for (const auto& err : checkResult.errors) {
      logloc::Log msg;
      msg.set_filename(err.filename);
      msg.set_message(err.message);
      msg.set_input_lines(get_lines(err.filename));
      msg.set_start_info(err.line, err.column); 
      msg.set_end_info(err.line, err.column + err.token.size());
      msg.set_kind("Type Error"); 
      msg.reveal_lines_after(3);
      msg.report();
    }
    for (const auto& err : codeGen.errors()) {
      logloc::Log msg;
      msg.set_filename(err.filename);
      msg.set_message(err.message);
      msg.set_input_lines(get_lines(err.filename));
      msg.set_start_info(err.line, err.column); 
      msg.set_end_info(err.line, err.column + err.token.size());
      msg.set_kind("Codegen Error"); 
      msg.reveal_lines_after(3);
      msg.report();
    }
  }

  if (cppCode.empty()) {
    return false;
  }

  if (printSource) {
    std::cout << cppCode;
  } else {
    std::string outPath = targetOutPath;
    if (outPath.empty()) {
      outPath = "output.cpp";
    }
    return write_cpp(outPath, cppCode);
  }
  return true;
}

void build_file(args::Subparser& parser) {
  args::Positional<std::string> file(parser, "FILE", "Source file to build.");

  args::Flag cpp(parser, "cpp", "Generate C++ source", {"cpp"});

  args::ValueFlag<std::string> outfile(parser, "output",
                                       "Output file name or path",
                                       {'o', "output"});

  args::ValueFlagList<std::string> libs_paths(
      parser, "lib-path", "Add a library search directory.",
      {'L', "lib-path"});

  args::ValueFlagList<std::string> include_paths(
      parser, "include-path", "Add a C++ header search directory.",
      {'I', "include-path"});

  args::ValueFlagList<std::string> lib_names(
      parser, "lib", "Link with a library (without the -l prefix).",
      {'l', "lib"});

  args::Flag _stdout(parser, "stdout", "Write to stdout", {"so"});
  parser.Parse();

  if (file) {
    std::string& input_path = file.Get();
    const std::string outputPath =
        outfile ? outfile.Get() : (cpp ? "output.cpp" : "output.exe");
    if (cpp) {
      if (!compile(input_path, outputPath, _stdout.Get())) {
        std::exit(EXIT_FAILURE);
      }
      return;
    }

    std::filesystem::path binaryPath(outputPath);
    std::filesystem::path cppPath(binaryPath);
    cppPath.replace_extension(".cpp");
    const std::string cppPathString = cppPath.string();
    const std::string binaryPathString = binaryPath.string();
    if (!compile(input_path, cppPathString, false)) {
      std::exit(EXIT_FAILURE);
    }

    Nob_Cmd cmd = {};
    nob_cmd_append(&cmd, "g++", "-std=c++26", "-Wno-write-strings", "-Wno-attributes", "-fpermissive",
                   cppPathString.c_str(), "-o", binaryPathString.c_str());
    std::vector<std::string> linkerFlags;
    linkerFlags.reserve(include_paths.Get().size() + libs_paths.Get().size() +
                        lib_names.Get().size());
    for (const auto& path : include_paths.Get()) {
      linkerFlags.push_back("-I" + path);
    }
    for (const auto& path : libs_paths.Get()) {
      linkerFlags.push_back("-L" + path);
    }
    for (const auto& name : lib_names.Get()) {
      linkerFlags.push_back("-l" + name);
    }
    for (const auto& linkerFlag : linkerFlags) {
      nob_cmd_append(&cmd, linkerFlag.c_str());
    }

    if (!nob_cmd_run(&cmd)) {
      std::cerr << "Error: failed to build final executable" << std::endl;
      std::exit(EXIT_FAILURE);
    }
  } else
    std::cout << "TODO: Build project";
}


void run(args::Subparser& parser) {
  args::Positional<std::string> file(parser, "FILE", "Source file to run.",
                                     args::Options::None);
  args::Group commands(parser, "extras");
  args::Flag _stdout(parser, "stdout", "lsp use stdio", {"stdio"});
  args::Flag lsp(parser, "lsp", "Start the lsp server", {"lsp"});

  parser.Parse();

  if (lsp || _stdout) {
    LSPServerConfig config;
    LSPServer server(config);
    server.run();
    return;
  }

  if (file)
    std::cout << "Running " << args::get(file) << '\n';
  else
    std::cout << "Running project\n";

}


int main(int argc, char** argv) {
  args::ArgumentParser parser(
      "glang cli", "The command line interface for the glang compiler");

  args::Group commands(parser, "commands");

  args::Command build_command(commands, "build",
                              "Build the project or source file.", &build_file);

  args::Command run_command(commands, "run", "Run the project or source file.",
                            &run);

  args::HelpFlag help(parser, "HELP", "Display this help menu.", {'h', "help"});

  try {
    parser.ParseCLI(argc, argv);
  } catch (const args::Help&) {
    std::cout << parser;
    return 0;
  } catch (const args::Error& e) {
    std::cerr << "error: " << e.what() << '\n';
    for (int i = 0; i < argc; ++i) {
      std::cerr << argv[i] << std::endl;
    }
    std::cerr << parser;
    return 1;
  }

  return 0;
}
