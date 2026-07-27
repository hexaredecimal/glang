#include <fstream>
#include <iostream>
#include <string>
#include <vector>

struct Change {
    std::string date;
    std::string title;
    std::string message;
};

bool parseChange(std::istream& in, Change& change) {
    std::string line;

    while (std::getline(in, line)) {
        if (!line.empty())
            break;
    }

    if (in.eof() && line.empty())
        return false;

    size_t open = line.find('[');
    size_t close = line.find(']');

    if (open == std::string::npos || close == std::string::npos) {
        std::cerr << "Invalid line (missing date): " << line << '\n';
        return false;
    }

    change.date = line.substr(open + 1, close - open - 1);

    size_t colon = line.find(':', close);
    if (colon == std::string::npos) {
        std::cerr << "Invalid line (missing colon): " << line << '\n';
        return false;
    }

    size_t titleStart = close + 1;

    while (titleStart < colon && line[titleStart] == ' ')
        ++titleStart;

    change.title = line.substr(titleStart, colon - titleStart);

    size_t messageStart = colon + 1;
    while (messageStart < line.size() && line[messageStart] == ' ')
        ++messageStart;

    change.message = line.substr(messageStart);

    while (!change.message.empty() && change.message.back() == '\\') {
        change.message.pop_back();

        std::string next;
        if (!std::getline(in, next))
            break;

        change.message += '\n';
        change.message += next;
    }

    return true;
}

int main(int argc, char**argv) {

    if (argc == 1) {
      std::cout << "Usage: changelog CHANGELOG > file.json" << std::endl;
      return 1;
    }


    const char* input = argv[1]; 

    std::ifstream file(input);

    if (!file.is_open()) {
        std::cerr << "Could not open `" << input << "`" << std::endl;
        return 1;
    }

    Change change;
    std::vector<Change> v{};
    while (parseChange(file, change)) {
        v.push_back(change);
    }


    std::cout << "{" << std::endl;
    std::cout << "  \"updates\" : [" << std::endl;

    int count = v.size();
    for (int i = 0; i < count; ++i) {
      Change c = v[i];
      std::cout << "    {" << std::endl;
      {
        std::cout << "      \"date\": \"" << c.date << "\"," << std::endl;
        std::cout << "      \"title\": \"" << c.title << "\"," << std::endl;
        std::cout << "      \"description\": \"" << c.message << "\"" << std::endl;
      }
      std::cout << "    }";

      if (i < count - 1)
        std::cout << "," << std::endl;
      else std::cout << std::endl;

    }

    std::cout << "  ]" << std::endl;
    std::cout << "}" << std::endl;
    return 0;
}