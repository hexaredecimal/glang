# Raven workspace in Glang

This is a Glang port of Raven's workspace example. It uses the namespaced
`raven::` declarations in `raven.g`; the layout and widgets remain in
`workspace.xml`. Callback bindings accept capturing Glang closures and retain
them behind C-compatible trampolines, following the callable-storage pattern
in Raven's C++ binding.

The sample expects Raven's static library in the MSYS2 home `.local` prefix
and should be built from the Glang repository root in an MSYS2 MINGW64
environment:

```sh
build/gcli.exe build examples/workspace/workspace.g \
  -o build/workspace.exe \
  -L "$HOME/.local/lib" \
  -l raven -l winhttp -l gdi32 -l ole32 -l oleaut32 -l uuid \
  -l comdlg32 -l comctl32 -l shlwapi -l shell32 -l user32 \
  -l ws2_32 -l crypt32 -l dwmapi
```

Run `build/workspace.exe` from the repository root so the relative XML path
resolves. The Windows system libraries above satisfy dependencies of the
installed static `libraven.a`; other Raven builds may need different link
flags. The C ABI declarations and numeric enum constants in this example are
for Raven 0.2.x and should be checked against `Raven.h` when upgrading. The
`-I .` option lets generated C++ find the callback bridge header.

The port and XML retain their upstream attribution. See `NOTICE` and
`LICENSE-APACHE-2.0`.
