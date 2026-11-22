
import std.string.prelude;

[[extern]]
double atof(const char* s); 

[[extern]]
int atoi(const char* s); 

[[extern]]
long atol(const char* s); 

double std::string::to_double(const char* s) => s.atof();

int std::string::to_int(const char* s) => s.atoi();

long std::string::to_long(const char* s) => s.atol();

double to_double(const char* s) => std::string::to_double(s);
int to_int(const char* s) => std::string::to_int(s);
long to_long(const char* s) => std::string::to_long(s);

