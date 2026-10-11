#ifndef COMPILER_LOCATION_HPP
#define COMPILER_LOCATION_HPP

#include <string>

namespace Glang {

struct Location {
    std::string filename;
    int line{1};
    int column{1};

    Location() = default;
    Location(std::string fn, int l, int c)
        : filename(std::move(fn)), line(l), column(c) {}

    std::string toString() const {
        return filename + ":" + std::to_string(line) + ":" + std::to_string(column);
    }
};

}  // namespace Glang

#endif
