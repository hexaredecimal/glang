import std.chars.prelude;


[[extern]]
int isalnum(int _C);

[[extern]]
int isalpha(int _C);

[[extern]]
int isblank(int _C);

[[extern]]
int iscntrl(int _C);

[[extern]]
int isdigit(int _C);

[[extern]]
int isgraph(int _C);

[[extern]]
int islower(int _C);

[[extern]]
int isprint(int _C);

[[extern]]
int ispunct(int _C);

[[extern]]
int isspace(int _C);

[[extern]]
int isupper(int _C);

[[extern]]
int isxdigit(int _C);

[[extern]]
int tolower(int _C);

[[extern]]
int toupper(int _C);


bool std::chars::is_alphanumeric(char c)  => isalnum(c as int) != 0;
bool std::chars::is_alphabet(char c)  => isalpha(c as int) != 0;
bool std::chars::is_blank(char c)  => isblank(c as int) != 0;
bool std::chars::is_control(char c)  => iscntrl(c as int) != 0;
bool std::chars::is_digit(char c)  => isdigit(c as int) != 0;
bool std::chars::is_graph(char c)  => isgraph(c as int) != 0;
bool std::chars::is_lower(char c)  => islower(c as int) != 0;
bool std::chars::is_printable(char c)  => isprint(c as int) != 0;
bool std::chars::is_punctuation(char c)  => ispunct(c as int) != 0;
bool std::chars::is_space(char c)  => isspace(c as int) != 0;
bool std::chars::is_upper(char c)  => isupper(c as int) != 0;
bool std::chars::is_xdigit(char c) => isxdigit(c as int) != 0;

char std::chars::to_lower(char c)  => tolower(c as int) as char;
char std::chars::to_upper(char c)  => toupper(c as int) as char;


bool is_alphanumeric(char c)  => std::chars::is_alphanumeric(c);
bool is_alphabet(char c)  => std::chars::is_alphabet(c);
bool is_blank(char c)  => std::chars::is_blank(c);
bool is_control(char c)  => std::chars::is_control(c);
bool is_digit(char c)  => std::chars::is_digit(c);
bool is_graph(char c)  => std::chars::is_graph(c);
bool is_lower(char c)  => std::chars::is_lower(c);
bool is_printable(char c)  => std::chars::is_printable(c);
bool is_punctuation(char c)  => std::chars::is_punctuation(c);
bool is_space(char c)  => std::chars::is_space(c);
bool is_upper(char c)  => std::chars::is_upper(c);
bool is_xdigit(char c) => std::chars::is_xdigit(c);

char to_lower(char c)  => std::chars::to_lower(c);
char to_upper(char c)  => std::chars::to_upper(c);

