
import std.io.print;
import std.string.dup;
import std.memory.c.alloc;

struct JsonParser {
  const char* source;
  int position;
  int length;
  int depth;
}

struct JsonValue {
  const char* source;
  int start;
  int end;
  bool valid;
}

struct JsonText {
  // Borrowed view; it is valid as long as the source is alive, and escapes
  // remain encoded in the slice.
  const char* source;
  int start;
  int length;
  bool valid;
}

struct JsonNumberResult {
  double value;
  bool ok;
}

struct JsonBooleanResult {
  bool value;
  bool ok;
}

bool isDigit(char value) =>
    value >= '0' && value <= '9';

bool isHexDigit(char value) =>
    (value >= '0' && value <= '9') ||
    (value >= 'a' && value <= 'f') ||
    (value >= 'A' && value <= 'F');

int stringLength(const char* value) {
  int length = 0;
  while (value[length] != 0) {
    length = length + 1;
  }
  return length;
}

void skipWhitespace(JsonParser* parser) {
  while (parser.position < parser.length) {
    char value = parser.source[parser.position];
    if (value == 32 || value == 9 || value == 10 || value == 13) {
      parser.position = parser.position + 1;
    } else {
      return;
    }
  }
}

bool parseString(JsonParser* parser) {
  if (parser.position >= parser.length ||
      parser.source[parser.position] != '"') {
    return false;
  }

  parser.position = parser.position + 1;
  while (parser.position < parser.length) {
    char value = parser.source[parser.position];
    parser.position = parser.position + 1;

    if (value == '"') {
      return true;
    }
    if (value < 32) {
      return false;
    }
    if (value == 92) {
      if (parser.position >= parser.length) {
        return false;
      }

      char escaped = parser.source[parser.position];
      parser.position = parser.position + 1;
      if (escaped == 34 || escaped == 92 || escaped == 47 ||
          escaped == 98 || escaped == 102 || escaped == 110 ||
          escaped == 114 || escaped == 116) {
        continue;
      }
      if (escaped != 117) {
        return false;
      }

      int digit = 0;
      while (digit < 4) {
        if (parser.position >= parser.length ||
            !isHexDigit(parser.source[parser.position])) {
          return false;
        }
        parser.position = parser.position + 1;
        digit = digit + 1;
      }
    }
  }
  return false;
}

bool parseNumber(JsonParser* parser) {
  if (parser.source[parser.position] == '-') {
    parser.position = parser.position + 1;
    if (parser.position >= parser.length) {
      return false;
    }
  }

  if (parser.source[parser.position] == '0') {
    parser.position = parser.position + 1;
    if (parser.position < parser.length &&
        isDigit(parser.source[parser.position])) {
      return false;
    }
  } else {
    if (parser.source[parser.position] < '1' ||
        parser.source[parser.position] > '9') {
      return false;
    }
    while (parser.position < parser.length &&
           isDigit(parser.source[parser.position])) {
      parser.position = parser.position + 1;
    }
  }

  if (parser.position < parser.length &&
      parser.source[parser.position] == '.') {
    parser.position = parser.position + 1;
    if (parser.position >= parser.length ||
        !isDigit(parser.source[parser.position])) {
      return false;
    }
    while (parser.position < parser.length &&
           isDigit(parser.source[parser.position])) {
      parser.position = parser.position + 1;
    }
  }

  if (parser.position < parser.length &&
      (parser.source[parser.position] == 'e' ||
       parser.source[parser.position] == 'E')) {
    parser.position = parser.position + 1;
    if (parser.position < parser.length &&
        (parser.source[parser.position] == '+' ||
         parser.source[parser.position] == '-')) {
      parser.position = parser.position + 1;
    }
    if (parser.position >= parser.length ||
        !isDigit(parser.source[parser.position])) {
      return false;
    }
    while (parser.position < parser.length &&
           isDigit(parser.source[parser.position])) {
      parser.position = parser.position + 1;
    }
  }
  return true;
}

bool parseLiteral(JsonParser* parser, const char* literal) {
  int offset = 0;
  while (literal[offset] != 0) {
    if (parser.position >= parser.length ||
        parser.source[parser.position] != literal[offset]) {
      return false;
    }
    parser.position = parser.position + 1;
    offset = offset + 1;
  }
  return true;
}

bool parseValue(JsonParser* parser) {
  skipWhitespace(parser);
  if (parser.position >= parser.length) {
    return false;
  }

  char value = parser.source[parser.position];
  if (value == '"') {
    return parseString(parser);
  }
  if (value == '[') {
    parser.depth = parser.depth + 1;
    if (parser.depth > 128) {
      return false;
    }
    parser.position = parser.position + 1;
    skipWhitespace(parser);
    if (parser.position < parser.length &&
        parser.source[parser.position] == ']') {
      parser.position = parser.position + 1;
      parser.depth = parser.depth - 1;
      return true;
    }
    while (parser.position < parser.length) {
      if (!parseValue(parser)) {
        return false;
      }
      skipWhitespace(parser);
      if (parser.position < parser.length &&
          parser.source[parser.position] == ']') {
        parser.position = parser.position + 1;
        parser.depth = parser.depth - 1;
        return true;
      }
      if (parser.position >= parser.length ||
          parser.source[parser.position] != ',') {
        return false;
      }
      parser.position = parser.position + 1;
      skipWhitespace(parser);
    }
    return false;
  }
  if (value == '{') {
    parser.depth = parser.depth + 1;
    if (parser.depth > 128) {
      return false;
    }
    parser.position = parser.position + 1;
    skipWhitespace(parser);
    if (parser.position < parser.length &&
        parser.source[parser.position] == '}') {
      parser.position = parser.position + 1;
      parser.depth = parser.depth - 1;
      return true;
    }
    while (parser.position < parser.length) {
      if (!parseString(parser)) {
        return false;
      }
      skipWhitespace(parser);
      if (parser.position >= parser.length ||
          parser.source[parser.position] != ':') {
        return false;
      }
      parser.position = parser.position + 1;
      skipWhitespace(parser);
      if (!parseValue(parser)) {
        return false;
      }
      skipWhitespace(parser);
      if (parser.position < parser.length &&
          parser.source[parser.position] == '}') {
        parser.position = parser.position + 1;
        parser.depth = parser.depth - 1;
        return true;
      }
      if (parser.position >= parser.length ||
          parser.source[parser.position] != ',') {
        return false;
      }
      parser.position = parser.position + 1;
      skipWhitespace(parser);
    }
    return false;
  }
  if (value == 't') {
    return parseLiteral(parser, "true");
  }
  if (value == 'f') {
    return parseLiteral(parser, "false");
  }
  if (value == 'n') {
    return parseLiteral(parser, "null");
  }
  if (value == '-' || isDigit(value)) {
    return parseNumber(parser);
  }
  return false;
}

bool parseJson(const char* source) {
  JsonParser parser = JsonParser{source, 0, stringLength(source), 0};
  if (!parseValue(&parser)) {
    return false;
  }
  skipWhitespace(&parser);
  return parser.position == parser.length;
}

JsonValue jsonParse(const char* source) {
  JsonParser parser = JsonParser{source, 0, stringLength(source), 0};
  skipWhitespace(&parser);
  int start = parser.position;
  if (!parseValue(&parser)) {
    return JsonValue{source, 0, 0, false};
  }
  int end = parser.position;
  skipWhitespace(&parser);
  if (parser.position != parser.length) {
    return JsonValue{source, 0, 0, false};
  }
  return JsonValue{source, start, end, true};
}

JsonValue jsonGet(JsonValue object, const char* key) {
  if (!object.valid || object.source[object.start] != '{') {
    return JsonValue{object.source, 0, 0, false};
  }

  JsonParser parser = JsonParser{object.source, object.start + 1, object.end, 0};
  int keyLength = stringLength(key);
  skipWhitespace(&parser);
  while (parser.position < parser.length &&
         parser.source[parser.position] != '}') {
    int keyStart = parser.position + 1;
    if (!parseString(&parser)) {
      return JsonValue{object.source, 0, 0, false};
    }
    int currentKeyLength = parser.position - keyStart - 1;
    bool matches = currentKeyLength == keyLength;
    int i = 0;
    while (matches && i < keyLength) {
      if (parser.source[keyStart + i] != key[i]) {
        matches = false;
      }
      i = i + 1;
    }

    skipWhitespace(&parser);
    if (parser.position >= parser.length ||
        parser.source[parser.position] != ':') {
      return JsonValue{object.source, 0, 0, false};
    }
    parser.position = parser.position + 1;
    skipWhitespace(&parser);
    int valueStart = parser.position;
    if (!parseValue(&parser)) {
      return JsonValue{object.source, 0, 0, false};
    }
    int valueEnd = parser.position;
    if (matches) {
      return JsonValue{object.source, valueStart, valueEnd, true};
    }

    skipWhitespace(&parser);
    if (parser.position >= parser.length ||
        parser.source[parser.position] != ',') {
      return JsonValue{object.source, 0, 0, false};
    }
    parser.position = parser.position + 1;
    skipWhitespace(&parser);
  }
  return JsonValue{object.source, 0, 0, false};
}

JsonValue jsonAt(JsonValue array, int index) {
  if (!array.valid || array.source[array.start] != '[' || index < 0) {
    return JsonValue{array.source, 0, 0, false};
  }

  JsonParser parser = JsonParser{array.source, array.start + 1, array.end, 0};
  skipWhitespace(&parser);
  int current = 0;
  while (parser.position < parser.length &&
         parser.source[parser.position] != ']') {
    int valueStart = parser.position;
    if (!parseValue(&parser)) {
      return JsonValue{array.source, 0, 0, false};
    }
    int valueEnd = parser.position;
    if (current == index) {
      return JsonValue{array.source, valueStart, valueEnd, true};
    }
    current = current + 1;
    skipWhitespace(&parser);
    if (parser.position >= parser.length ||
        parser.source[parser.position] != ',') {
      return JsonValue{array.source, 0, 0, false};
    }
    parser.position = parser.position + 1;
    skipWhitespace(&parser);
  }
  return JsonValue{array.source, 0, 0, false};
}

JsonText jsonAsString(JsonValue value) {
  if (!value.valid || value.source[value.start] != '"') {
    return JsonText{value.source, 0, 0, false};
  }
  return JsonText{value.source, value.start + 1, value.end - value.start - 2,
                  true};
}


bool jsonTextEquals(JsonText value, const char* expected) {
  if (!value.valid) {
    return false;
  }
  int expectedLength = stringLength(expected);
  if (value.length != expectedLength) {
    return false;
  }
  int i = 0;
  while (i < expectedLength) {
    if (value.source[value.start + i] != expected[i]) {
      return false;
    }
    i = i + 1;
  }
  return true;
}

JsonNumberResult jsonAsNumber(JsonValue value) {
  if (!value.valid ||
      (!isDigit(value.source[value.start]) &&
       value.source[value.start] != '-')) {
    return JsonNumberResult{0.0, false};
  }

  int position = value.start;
  bool negative = false;
  if (value.source[position] == '-') {
    negative = true;
    position = position + 1;
  }

  double number = 0.0;
  while (position < value.end && isDigit(value.source[position])) {
    number = number * 10.0 + (value.source[position] - '0');
    position = position + 1;
  }
  if (position < value.end && value.source[position] == '.') {
    position = position + 1;
    double place = 0.1;
    while (position < value.end && isDigit(value.source[position])) {
      number = number + (value.source[position] - '0') * place;
      place = place / 10.0;
      position = position + 1;
    }
  }

  int exponent = 0;
  bool exponentNegative = false;
  if (position < value.end &&
      (value.source[position] == 'e' || value.source[position] == 'E')) {
    position = position + 1;
    if (value.source[position] == '-') {
      exponentNegative = true;
      position = position + 1;
    } else if (value.source[position] == '+') {
      position = position + 1;
    }
    while (position < value.end && isDigit(value.source[position])) {
      if (exponent < 10000) {
        exponent = exponent * 10 + value.source[position] - '0';
      }
      position = position + 1;
    }
  }

  if (position != value.end) {
    return JsonNumberResult{0.0, false};
  }
  while (exponent > 0) {
    if (exponentNegative) {
      number = number / 10.0;
    } else {
      number = number * 10.0;
    }
    exponent = exponent - 1;
  }
  if (negative) {
    number = -number;
  }
  return JsonNumberResult{number, true};
}

JsonBooleanResult jsonAsBoolean(JsonValue value) {
  if (!value.valid) {
    return JsonBooleanResult{false, false};
  }
  if (value.end - value.start == 4 &&
      value.source[value.start] == 't' &&
      value.source[value.start + 1] == 'r' &&
      value.source[value.start + 2] == 'u' &&
      value.source[value.start + 3] == 'e') {
    return JsonBooleanResult{true, true};
  }
  if (value.end - value.start == 5 &&
      value.source[value.start] == 'f' &&
      value.source[value.start + 1] == 'a' &&
      value.source[value.start + 2] == 'l' &&
      value.source[value.start + 3] == 's' &&
      value.source[value.start + 4] == 'e') {
    return JsonBooleanResult{false, true};
  }
  return JsonBooleanResult{false, false};
}

bool jsonIsNull(JsonValue value) {
  return value.valid &&
      value.end - value.start == 4 &&
      value.source[value.start] == 'n' &&
      value.source[value.start + 1] == 'u' &&
      value.source[value.start + 2] == 'l' &&
      value.source[value.start + 3] == 'l';
}

void main() {
  const char* document = "{\"name\":\"Ada\",\"active\":true,\"score\":-12.5e+2,\"items\":[null,false,{\"escaped\":\"quote: \\\"\"}]}";
  auto root = document.jsonParse();
  auto name = root.jsonGet("Name").jsonAsString();
  
  /*JsonValue root = jsonParse(document);
  JsonText name = jsonAsString(jsonGet(root, "name"));
  JsonBooleanResult active = jsonAsBoolean(jsonGet(root, "active"));
  JsonNumberResult score = jsonAsNumber(jsonGet(root, "score"));
  JsonValue items = jsonGet(root, "items");
  JsonBooleanResult secondItem = jsonAsBoolean(jsonAt(items, 1));
  JsonValue firstItem = jsonAt(items, 0);
  JsonValue thirdItem = jsonAt(items, 2);
  JsonText escaped = jsonAsString(jsonGet(thirdItem, "escaped"));

  if (!root.valid || !jsonTextEquals(name, "Ada") ||
      !active.ok || !active.value || !score.ok || score.value != -1250.0 ||
      !secondItem.ok || secondItem.value || !jsonIsNull(firstItem) ||
      !jsonTextEquals(escaped, "quote: \\\"") ||
      jsonAt(items, 3).valid || jsonGet(root, "missing").valid) {
    std::puts("typed JSON access failed");
    return;
  }

  std::puts("typed JSON access succeeded");

  if (jsonAsNumber(jsonGet(root, "name")).ok ||
      jsonAsBoolean(jsonGet(root, "missing")).ok ||
      jsonParse("{\"broken\":}").valid) {
    std::puts("invalid typed JSON access was accepted");
  } else {
    std::puts("wrong types, missing keys, and malformed JSON rejected");
  }*/
}
