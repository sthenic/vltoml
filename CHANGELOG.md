# CHANGELOG

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed

- Require Nim v1.4.0.

### Added

- Add `diagnostics` section to enable/disable particular diagnostic messages.
- Add `vls.indent_size`, `vls.tabs_to_spaces` and
  `vls.space_in_named_connection` to configure source code style for completion
  requests.
- Add `vls.cache_workspace_on_open` to enable/disable caching the entire
  workspace when opening a file.

### Fixed

- Strip trailing `/` characters from include paths.
- Fix not handling `~` properly in include paths.

## [v0.1.0] - 2020-08-08

- This is the first release of the project.
