#ifndef COMPILER_ERROR_HPP
#define COMPILER_ERROR_HPP

#include "Location.hpp"
#include <string>

namespace Glang {

struct Error {
    std::string message;
    int line{0};
    int column{0};
    std::string filename;
    std::string token;

    Error() = default;
    Error(std::string msg, int l, int c, std::string fn, std::string tok = "")
        : message(std::move(msg)), line(l), column(c), filename(std::move(fn)), token(std::move(tok)) {}

    Error(const Location& loc, std::string msg, std::string tok = "")
        : message(std::move(msg)), line(loc.line), column(loc.column), filename(loc.filename), token(std::move(tok)) {}

    std::string toString() const {
        std::string res = filename.empty() ? "" : filename + ":";
        res += std::to_string(line) + ":" + std::to_string(column) + ": error: " + message;
        if (!token.empty()) {
            res += " (at token '" + token + "')";
        }
        return res;
    }
};

using CompilerError = Error;

}  // namespace Glang

#endif
