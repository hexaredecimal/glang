#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "args/args.hpp"
#include "compiler/CodeGen.hpp"
#include "compiler/LSPServer.hpp"
#include "compiler/Lexer.hpp"
#include "compiler/Parser.hpp"
#include "compiler/TypeChecker.hpp"

#define NOB_IMPLEMENTATION
#include "../nob.h"

using namespace Glang;

void write_il(std::string& path, std::string& ilcode) {
  std::ofstream outFile(path);
  if (!outFile.is_open()) {
    std::cerr << "Error: Failed to write to file: " << path << std::endl;
    return;
  }

  outFile << ilcode;
}

void compile(std::string& filePath, std::string targetOutPath, bool write_ir,
             bool print_ir) {
  std::string code = "";
  std::ifstream file(filePath);
  if (!file.is_open()) {
    std::cerr << "Error: Could not open file " << filePath << std::endl;
    return;
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

  CodeGen codeGen;
  std::string ilCode;

  bool hasErrors =
      lexer.hasErrors() || parser.hasErrors() || checkResult.hasErrors();

  if (!hasErrors && ast) {
    ilCode = codeGen.generate(ast);
    if (codeGen.hasErrors()) {
      hasErrors = true;
    }
  }

  // TODO: Add a better error printer.
  if (hasErrors) {
    for (const auto& err : lexer.errors()) {
      std::cerr << "[" << err.filename << ":" << err.line << ":" << err.column
                << "] Lexer Error: " << err.message << std::endl;
    }
    for (const auto& err : parser.errors()) {
      std::cerr << "[" << err.filename << ":" << err.line << ":" << err.column
                << "] Parse Error: " << err.message << std::endl;
    }
    for (const auto& err : checkResult.errors) {
      std::cerr << "[" << err.filename << ":" << err.line << ":" << err.column
                << "] Type Error: " << err.message << std::endl;
    }
    for (const auto& err : codeGen.errors()) {
      std::cerr << "[" << err.filename << ":" << err.line << ":" << err.column
                << "] CodeGen Error: " << err.message << std::endl;
    }
  }

  if (ilCode.empty()) {
    return;
  }

  if (write_ir && !print_ir) {
    write_il(targetOutPath, ilCode);
  } else if (write_ir && print_ir) {
    std::cout << ilCode;
  } else {
    // TODO: Build the exe on all platforms
    std::string ilPath = targetOutPath + ".il";
    write_il(ilPath, ilCode);
    Nob_Cmd cmd = {0};

    nob_cmd_append(&cmd, "ilasm", ilPath.c_str(), "/output",
                   targetOutPath.c_str());

    if (!nob_cmd_run(&cmd)) {
      std::cout << "Error: Assembly error: Failed to create executable"
                << std::endl;
      nob_delete_file(ilPath.c_str());
      return;
    }

    nob_delete_file(ilPath.c_str());
  }
}

void build_file(args::Subparser& parser) {
  args::Positional<std::string> file(parser, "FILE", "Source file to build.");

  args::Flag ir(parser, "ir", "Generate DotNET IL", {"ir"});

  args::ValueFlag<std::string> outfile(parser, "output",
                                       "Output file name or path", {"o"});

  args::Flag _stdout(parser, "stdout", "Write to stdout", {"so"});
  parser.Parse();

  if (file) {
    std::string& file_path = args::get(file);

    if (outfile)
      compile(file_path, args::get(outfile), ir.Get(), _stdout.Get());
    else {
      compile(file_path, ir.Get() ? "output.il" : "output.exe", ir.Get(),
              _stdout.Get());
    }
  } else
    std::cout << "TODO: Build project";
}

void run(args::Subparser& parser) {
  args::Positional<std::string> file(parser, "FILE", "Source file to run.",
                                     args::Options::None);

  args::Flag lsp(parser, "lsp", "Start the lsp server on stdio.", {'l', "lsp"});

  parser.Parse();

  if (lsp) {
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

    std::cerr << parser;

    return 1;
  }

  return 0;
}
