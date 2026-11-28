import std.string.prelude;
import std.string.builder;
import std.string.string;
import std.string.len;
import std.container.list;

struct std::string::split {} // Module namespace

/// A non-owning view over a delimited string. The underlying text must stay
/// alive while the view is used. Segments are not copied or terminated.
struct SplitView {
    const char* text;
    char delimiter;
    int length;
    int offset;
    int count;
}

int count_text(const char* text, char delimiter) {
    if (text == nullptr || text[0] == '\0') {
        return 1;
    }
    int count = 1;
    int index = 0;
    while (text[index] != '\0') {
        if (text[index] == delimiter) {
            count = count + 1;
        }
        index = index + 1;
    }
    return count;
}

int std::string::split::count(const char* text, char delimiter) =>
    count_text(text, delimiter);
int count(const char* text, char delimiter) =>
    count_text(text, delimiter);

/// Create a view for iterating the delimiter-separated segments of `text`.
SplitView SplitView::new(const char* text, char delimiter) {
    SplitView view;
    view.text = text;
    view.delimiter = delimiter;
    view.length = 0;
    view.offset = 0;
    view.count = 0;
    if (text != nullptr) {
        while (text[view.length] != '\0') {
            view.length = view.length + 1;
        }
    }
    view.count = count_text(text, delimiter);
    return view;
}

SplitView std::string::split::view(const char* text, char delimiter) =>
    SplitView::new(text, delimiter);

/// Return the next segment as (pointer, length, found). `found` is false once
/// every segment has been consumed. Empty segments are returned normally.
[[no_custom_operators]]
(const char*, int, bool) next(SplitView* view) {
    if (view == nullptr || view.offset > view.length) {
        return ("", 0, false);
    }
    int start = view.offset;
    int end = start;
    while (end < view.length && view.text[end] != view.delimiter) {
        end = end + 1;
    }
    if (end < view.length) {
        view.offset = end + 1;
    } else {
        view.offset = view.length + 1;
    }
    return (view.text + start, end - start, true);
}

(const char*, int, bool) std::string::split::next(SplitView* view) =>
    next(view);

/// Split `text` into independently owned `String` segments. The input is not
/// modified; every returned segment owns its own storage.
[[no_custom_operators]]
List<String> split(const char* text, char delimiter) {
    List<String> parts = List<String>::new();
    if (text == nullptr) {
        return parts;
    }
    int length = std::string::length(text) as int;
    int start = 0;
    for (int index = 0; index <= length; index = index + 1) {
        if (index == length || text[index] == delimiter) {
            parts.push_back(String::from(text + start,
                                         (index - start) as ulong));
            start = index + 1;
        }
    }
    return parts;
}

List<String> std::string::split::segments(const char* text,
                                          char delimiter) =>
    split(text, delimiter);

/// String-receiver form.
List<String> String::split(String* self, char delimiter) =>
    split(String::c_str(self), delimiter);

/// Join a list of borrowed strings into a fixed-capacity StringBuilder.
StringBuilder join(List<char*> parts, const char* separator) {
    StringBuilder result = StringBuilder::new();
    for (int index = 0; index < parts.length; index = index + 1) {
        if (index > 0) {
            result = builder_append_text(result, separator);
        }
        result = builder_append_text(result, parts[index]);
    }
    return result;
}

/// Join a list of owned strings into a fixed-capacity StringBuilder.
StringBuilder join(List<String> parts, const char* separator) {
    StringBuilder result = StringBuilder::new();
    for (int index = 0; index < parts.length; index = index + 1) {
        if (index > 0) {
            result = builder_append_text(result, separator);
        }
        result = builder_append_text(result, parts[index].c_str());
    }
    return result;
}

StringBuilder std::string::split::join(List<char*> parts,
                                       const char* separator) =>
    join(parts, separator);

StringBuilder std::string::split::join(List<String> parts,
                                       const char* separator) =>
    join(parts, separator);

/// Join every segment of a SplitView.
StringBuilder join(SplitView view, const char* separator) {
    StringBuilder result = StringBuilder::new();
    bool first = true;
    while (true) {
        auto (segment, length, found) = next(&view);
        if (!found) {
            break;
        }
        if (!first) {
            result = builder_append_text(result, separator);
        }
        first = false;
        for (int index = 0; index < length; index = index + 1) {
            result = builder_append_char(result, segment[index]);
        }
    }
    return result;
}

StringBuilder std::string::split::join(SplitView view,
                                       const char* separator) =>
    join(view, separator);
