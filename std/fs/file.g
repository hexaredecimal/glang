
import std.fs.prelude;

type File = FILE;

type Mode = const char*;

Mode Mode::Write = "w";
Mode Mode::Read = "r";
Mode Mode::ReadAndWrite = "wr";


type Seek = int;

Seek Seek::Current = 1;
Seek Seek::End = 2;
Seek Seek::Reset = 0;

[[extern, c_abi]]
File* fopen(const char* path, Mode mode);
(File*, bool) std::file::open(const char* path, Mode mode) {
  auto fp = fopen(path, mode);
  if (fp == nullptr) {
    return (nullptr, false);
  }
  return (fp, true);
}

[[extern, c_abi]]
int fseek(File* fp, long offset, Seek whence);

[[extern, c_abi]]
long ftell(File* fp);

[[extern, c_abi]]
int fclose(File* fp);

[[extern, c_abi]]
size_t fread(void* buffer, size_t elementSize, size_t elementCount,
             File* fp);

[[extern, c_abi]]
size_t fwrite(const void* buffer, size_t elementSize, size_t elementCount,
              File* fp);

long get_size(const File* fp) {
  fp.fseek(0, Seek::End);
  defer fp.fseek(0, Seek::Reset);
  return fp.ftell();
}

long std::file::get_Size(const File* fp) => fp.get_size();

bool std::fs::exists(const char* path) {
  if (path == nullptr) {
    return false;
  }
  auto (fp, ok) = std::file::open(path, Mode::Read);
  if (ok && fp != nullptr) {
    fclose(fp);
    return true;
  }
  return false;
}

bool file_exists(const char* path) => std::fs::exists(path);

