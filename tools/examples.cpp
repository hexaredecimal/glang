#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

namespace fs = std::filesystem;

std::string read_file(const fs::path& path) {
    std::ifstream file(path, std::ios::binary);
    if (!file)
        return "";

    std::ostringstream ss;
    ss << file.rdbuf();
    return ss.str();
}

std::string escape_json(const std::string& str) {
    std::string out;
    out.reserve(str.size());

    for (char c : str) {
        switch (c) {
            case '\"': out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\b': out += "\\b"; break;
            case '\f': out += "\\f"; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            default:
                if (static_cast<unsigned char>(c) < 0x20) {
                    char buf[7];
                    snprintf(buf, sizeof(buf), "\\u%04x",
                             static_cast<unsigned char>(c));
                    out += buf;
                } else {
                    out += c;
                }
        }
    }

    return out;
}

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <directory>\n";
        return 1;
    }

    fs::path root = argv[1];

    if (!fs::exists(root) || !fs::is_directory(root)) {
        std::cerr << "Invalid directory.\n";
        return 1;
    }

    std::cout << "{\n";
    std::cout << "  \"files\": [\n";

    bool first = true;

    for (const auto& entry : fs::recursive_directory_iterator(root)) {
        if (!entry.is_regular_file())
            continue;

        if (entry.path().extension() != ".g")
            continue;

        if (!first)
            std::cout << ",\n";

        first = false;

        std::string code = read_file(entry.path());

        std::cout << "    {\n";
        std::cout << "      \"name\": \"" << escape_json(entry.path().filename().string()) << "\",\n";
        std::cout << "      \"code\": \"" << escape_json(code) << "\"\n";
        std::cout << "    }";
    }

    std::cout << "\n";
    std::cout << "  ]\n";
    std::cout << "}\n";

    return 0;
}