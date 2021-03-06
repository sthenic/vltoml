[![NIM](https://img.shields.io/badge/Nim-1.4.0-orange.svg?style=flat-square)](https://nim-lang.org)
[![LICENSE](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)
![tests](https://github.com/sthenic/vltoml/workflows/tests/badge.svg)

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
    "../a/relative/path",
    "/a/recursive/include/**"
]

defines = [
    "FOO",
    "WIDTH=8",
    "ONES(x) = {(x){1'b1}}"
]

[vls]
max_nof_diagnostics = 10
cache_workspace_on_open = true
indent_size = 4
tabs_to_spaces = true
space_in_named_connection = false

[diagnostics]
undeclared_identifiers = true
unconnected_ports = true
missing_ports = true
missing_parameters = false
unassigned_parameters = true
```

### Top-level tables

- The `verilog` table collects language-specific settings.
- The `vls` table collects settings specific to the language server.
- The `diagnostics` table collects settings specific to diagnostic messages.

### `verilog` table

- `include_paths` is an array of strings expressing the include paths where
  `vls` should look for externally defined modules and files targeted by ``
  `include`` directives. By default, only the Verilog files immediately on the
  path are included, i.e. `/path/to/some/directory/*.v`, However, a recursive
  include may be specified by ending the path with `/**`, i.e.
  `/path/to/some/directory/**`.

- `defines` is an array of strings expressing the defines that should be passed
  to `vls`. The rules follow that of the `-D` option for
  [`vparse`](https://github.com/sthenic/vparse). It's possible to specify a
  macro by using the character `=` to separate the macro name from its body.

### `vls` table

- `max_nof_diagnostics` specifies the maximum number of diagnostic messages
  passed in a `textDocument/publishDiagnostics` notification. The default value
  is `-1` and implies no upper bound.

- `cache_workspace_on_open` specifies whether or not to attempt to cache *all*
  the modules present on the include paths (`verilog.include_paths`) when a new
  file is opened. The default value is `true`. If the value is set to `false`,
  then the degree to which the workspace is 'explored' depends on the module
  hierarchy seen from the opened file.

  For example, if an instantiation of module `A` is encountered and its
  declaration is unknown, the source files on the include paths will be analyzed
  until the declaration is found or the set of source files is exhausted. If the
  declaration of module `B` is also present on the include path, but not
  instantiated by any module, its declaration will remain unknown, unless it was
  discovered when searching for module `A`.

  Not exploring the full workspace affects module instantiation completions but
  comes with a positive impact on parsing speed for *very* large workspaces.

- `indent_size` specifies how many spaces to use for one level of indentation.
  The default value is `4`.

- `tabs_to_spaces` specifies whether or not to insert spaces instead of the tab
  character `\t` for indentation. The default value is `true`.

- `space_in_named_connection` specifies whether or not to insert a space when
  completing a named connection, i.e. `.clk_i()` vs. `.clk_i ()`. The default
  value is `false`.

### `diagnostics` table

- `undeclared_identifiers` specifies whether or not to publish diagnostic
  messages for undeclared identifiers. The default value is `true`.

- `unconnected_ports` specifies whether or not to publish diagnostic messages if
  a module instance has unconnected input ports. The default value is `true`.

- `missing_ports` specifies whether or not to publish diagnostic messages if a
  module instance doesn't list all the available ports. The default value is
  `true`.

- `missing_parameters` specifies whether or not to publish diagnostic messages
  if a module instantiation doesn't list all the available parameters. The
  default value is `false` since relying on default parameter values can be a
  intentional design strategy.

- `unassigned_parameters` specifies whether or not to publish diagnostic
  messages if a module instantiation has unassigned named parameter connections,
  e.g. `.WIDTH()`. The default value is `true`.

## Version numbers
Releases follow [semantic versioning](https://semver.org/) to determine how the version number is incremented. If the specification is ever broken by a release, this will be documented in the changelog.

## Reporting a bug
If you discover a bug or what you believe is unintended behavior, please submit
an issue on the [issue board](https://github.com/sthenic/vltoml/issues). A
minimal working example and a short description of the context is appreciated
and goes a long way towards being able to fix the problem quickly.

## License
This tool is free software released under the [MIT license](https://opensource.org/licenses/MIT).

## Third-party dependencies

* [Nim's standard library](https://github.com/nim-lang/Nim)
* [parsetoml](https://github.com/NimParsers/parsetoml)

## Author
`vltoml` is maintained by [Marcus Eriksson](mailto:marcus.jr.eriksson@gmail.com).
