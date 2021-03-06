import terminal
import strformat
import os

import vltoml

var nof_passed = 0
var nof_failed = 0

template run_test(title, stimuli: string, reference: Configuration, expect_error = false) =
   try:
      let response = parse_string(stimuli)
      if response == reference:
         styledWriteLine(stdout, styleBright, fgGreen, "[✓] ",
                        fgWhite, "Test '",  title, "'")
         inc(nof_passed)
      else:
         styledWriteLine(stdout, styleBright, fgRed, "[✗] ",
                        fgWhite, "Test '",  title, "'")
         inc(nof_failed)
         echo response
         echo reference
   except ConfigurationParseError as e:
      if expect_error:
         styledWriteLine(stdout, styleBright, fgGreen, "[✓] ",
                        fgWhite, "Test '",  title, "'")
         inc(nof_passed)
      else:
         styledWriteLine(stdout, styleBright, fgRed, "[✗] ",
                        fgWhite, "Test '",  title, "'")
         inc(nof_failed)
         echo e.msg


template run_test_file(title, filename: string, reference: Configuration, expect_error = false) =
   try:
      let response = parse_file(filename)
      if response == reference:
         styledWriteLine(stdout, styleBright, fgGreen, "[✓] ",
                        fgWhite, "Test '",  title, "'")
         inc(nof_passed)
      else:
         styledWriteLine(stdout, styleBright, fgRed, "[✗] ",
                        fgWhite, "Test '",  title, "'")
         inc(nof_failed)
         echo response
         echo reference
   except ConfigurationParseError as e:
      if expect_error:
         styledWriteLine(stdout, styleBright, fgGreen, "[✓] ",
                        fgWhite, "Test '",  title, "'")
         inc(nof_passed)
      else:
         styledWriteLine(stdout, styleBright, fgRed, "[✗] ",
                        fgWhite, "Test '",  title, "'")
         inc(nof_failed)
         echo e.msg


template run_test_find_file(title, stimuli, reference: string) =
   let response = find_configuration_file(stimuli)
   if response == expand_filename(reference):
      styledWriteLine(stdout, styleBright, fgGreen, "[✓] ",
                     fgWhite, "Test '",  title, "'")
      inc(nof_passed)
   else:
      styledWriteLine(stdout, styleBright, fgRed, "[✗] ",
                     fgWhite, "Test '",  title, "'")
      inc(nof_failed)
      echo response
      echo reference


proc new_configuration(max_nof_diagnostics: int,
                       undeclared_identifiers, unconnected_ports, missing_ports: bool,
                       include_paths, defines: seq[string]): Configuration =
   result.include_paths = include_paths
   result.defines = defines
   result.max_nof_diagnostics = max_nof_diagnostics
   result.diagnostics.undeclared_identifiers = undeclared_identifiers
   result.diagnostics.unconnected_ports = unconnected_ports
   result.diagnostics.missing_ports = missing_ports
   # FIXME: Better way to initialize a new configuration object for the test
   #        cases.
   result.diagnostics.missing_parameters = false
   result.diagnostics.unassigned_parameters = true
   result.cache_workspace_on_open = true
   result.tabs_to_spaces = true
   result.space_in_named_connection = false
   result.indent_size = 4


# Test suite title
styledWriteLine(stdout, styleBright,
"""

Test suite: configuration
-------------------------""")


run_test("verilog.include_paths", """
[verilog]
include_paths = [
    "/path/to/some/directory",
    "/path/to/another/directory",
    "../a/relative/path/",
    "../../another/relative/path/**/",
    "./a/path//to/..//normalize///",
    "C:\\a\\Windows\\path\\**"
]
""", new_configuration(-1, true, true, true, @[
    "/path/to/some/directory",
    "/path/to/another/directory",
    "../a/relative/path",
    "../../another/relative/path/**",
    "a/path/normalize",
    "C:\\a\\Windows\\path\\**"
], @[]))

run_test("verilog.defines", """
[verilog]
defines = [
    "FOO",
    "WIDTH=8",
    "ONES(x) = {(x){1'b1}}"
]""", new_configuration(-1, true, true, true, @[], @[
    "FOO",
    "WIDTH=8",
    "ONES(x) = {(x){1'b1}}"
]))


run_test("Parse error: invalid TOML", """
include_paths = [
    "An open string literal
]""", Configuration(), true)


run_test("Parse error: 'verilog.include_paths' is not an array", """
[verilog]
include_paths = "a simple string"
""", Configuration(), true)


run_test("Parse error: 'verilog.include_paths' is not an array of strings", """
[verilog]
include_paths = [1, 2, 3]
""", Configuration(), true)


run_test("Parse error: 'verilog.defines' is not an array", """
[verilog]
defines = 3.1459
""", Configuration(), true)


run_test("Parse error: 'verilog.defines' is not an array of strings", """
[verilog]
defines = [true, false]
""", Configuration(), true)


run_test_file("Parse from a file (trim whitespace)", "cfg.toml",
   new_configuration(-1, true, true, true, @[
      "/path/to/some/directory",
      "/path/to/another/directory",
      join_path(expand_filename("."), "../a/relative/path")
   ], @[
      "FOO",
      "WIDTH=8",
      "ONES(x) = {(x){1'b1}}"
   ])
)


run_test_file("Parse error: the file does not exist", "foo.toml", Configuration(), true)


run_test_find_file("Find '.vl.toml'.", "./", "./.vl/vl.toml")


run_test("vls.max_nof_diagnostics", """
[vls]
max_nof_diagnostics = 10
""", new_configuration(10, true, true, true, @[], @[]))


run_test("Parse error: 'vls.max_nof_diagnostics' is not an integer", """
[vls]
max_nof_diagnostics = "foo"
""", Configuration(), true)


run_test("Duplicate include path", """
[verilog]
include_paths = [
   "../tests",
   "../tests",
   "/path/to/dir/a",
   "/path/to/dir/b"
   "/path/to/dir/a"
]
""",
   new_configuration(-1, true, true, true, @[
      "../tests",
      "/path/to/dir/a",
      "/path/to/dir/b"
   ], @[])
)


run_test("diagnostics.undeclared_identifiers", """
[diagnostics]
undeclared_identifiers = false
""", new_configuration(-1, false, true, true, @[], @[]))


run_test("Parse error: 'diagnostics.undeclared_identifiers' is not a boolean", """
[diagnostics]
undeclared_identifiers = "false"
""", Configuration(), true)


run_test("diagnostics.unconnected_ports", """
[diagnostics]
unconnected_ports = false
""", new_configuration(-1, true, false, true, @[], @[]))


run_test("Parse error: 'diagnostics.unconnected_ports' is not a boolean", """
[diagnostics]
unconnected_ports = "false"
""", Configuration(), true)


run_test("diagnostics.missing_ports", """
[diagnostics]
missing_ports = false
""", new_configuration(-1, true, true, false, @[], @[]))


run_test("Parse error: 'diagnostics.missing_ports' is not a boolean", """
[diagnostics]
missing_ports = "false"
""", Configuration(), true)


# Print summary
styledWriteLine(stdout, styleBright, "\n----- SUMMARY -----")
var test_str = "test"
if nof_passed == 1:
   test_str.add(' ')
else:
   test_str.add('s')
styledWriteLine(stdout, styleBright, &" {$nof_passed:<4} ", test_str,
                fgGreen, " PASSED")

test_str = "test"
if nof_failed == 1:
   test_str.add(' ')
else:
   test_str.add('s')
styledWriteLine(stdout, styleBright, &" {$nof_failed:<4} ", test_str,
                fgRed, " FAILED")

styledWriteLine(stdout, styleBright, "-------------------")

quit(nof_failed)
