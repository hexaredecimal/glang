import std.types.prelude; 

int char::SIZE = sizeof(char);
int uchar::SIZE = sizeof(uchar);
int short::SIZE = sizeof(short);
int ushort::SIZE = sizeof(ushort);
int int::SIZE = sizeof(int);
int uint::SIZE = sizeof(uint);
float float::SIZE = sizeof(float);
double double::SIZE = sizeof(double);

ulong std::types::get_size<T>() => sizeof(T);
ulong get_size<T>() => std::types::get_size<T>();
