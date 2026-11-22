import std.fs.file;

[[private, extern, c_abi]]
File* __acrt_iob_func(uint ptr);

File* File::StdIn = __acrt_iob_func(0);
File* File::StdOut = __acrt_iob_func(1);
File* File::StdErr = __acrt_iob_func(2);

