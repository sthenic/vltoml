[![NIM](https://img.shields.io/badge/Nim-1.2.0-orange.svg?style=flat-square)](https://nim-lang.org)
[![LICENSE](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

# vltoml
This is a library to handle parsing of the TOML configuration file used by

- [`vls`](https://github.com/sthenic/vls) <span>&mdash;</span> a language server for Verilog IEEE 1364-2005.
- [`vlint`](https://github.com/sthenic/vlint) <span>&mdash;</span> a linter for Verilog IEEE 1364-2005.

## Documentation

The library includes a search algorithm that walks a provided path up to the root directory looking for one of the following files (listed in the order of precedence):

1. `.vl.toml`
2. `vl.toml`
3. `.vl/.vl.toml`
4. `.vl/vl.toml`
5. `vl/.vl.toml`
6. `vl/vl.toml`

In short, the configuration file can have two different names: `.vl.toml` or `vl.toml` and can reside immediately on the ascended path, or inside a directory named: `.vl/` or `vl/`.

### Example

```toml
[verilog]
include_paths = [
    "/path/to/some/directory",
    "/path/to/another/directory",
    "../a/relative/path"
]

defines = [
    "FOO",
    "WIDTH=8",
    "ONES(x) = {(x){1'b1}}"
]

[vls]
max_nof_diagnostics = 10
```

### Top-level tables

- The `verilog` table collects language-specific settings.
- The `vls` table collects settings specific to the language server.

### `verilog` table

- `include_paths` is an array of strings expressing the include paths where `vls` should look for externally defined modules and files targeted by `` `include`` directives.
- `defines` is an array of strings expressing the defines that should be passed to `vls`. The rules follow that of the `-D` option for [vparse](https://github.com/sthenic/vparse). It's possible to specify a macro by using the character `=` to separate the macro name from its body.

### `vls` table

- `max_nof_diagnostics` specifies the maximum number of diagnostic messages passed in a `textDocument/publishDiagnostics` notification.

## Version numbers
Releases follow [semantic versioning](https://semver.org/) to determine how the version number is incremented. If the specification is ever broken by a release, this will be documented in the changelog.

## Reporting a bug
If you discover a bug or what you believe is unintended behavior, please submit an issue on the [issue board](https://github.com/sthenic/vltoml/issues). A minimal working example and a short description of the context is appreciated and goes a long way towards being able to fix the problem quickly.

## License
This tool is free software released under the [MIT license](https://opensource.org/licenses/MIT).

## Third-party dependencies

* [Nim's standard library](https://github.com/nim-lang/Nim)
* [parsetoml](https://github.com/NimParsers/parsetoml)

## Author
`vltoml` is maintained by [Marcus Eriksson](mailto:marcus.jr.eriksson@gmail.com).
