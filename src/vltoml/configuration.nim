import parsetoml
import strutils
import os

type
   Diagnostics* = object
      undeclared_identifiers*: bool
      unconnected_ports*: bool
      missing_ports*: bool

   Configuration* = object
      include_paths*: seq[string]
      defines*: seq[string]
      max_nof_diagnostics*: int
      diagnostics*: Diagnostics

   ConfigurationParseError* = object of ValueError


proc new_configuration_parse_error(msg: string, args: varargs[string, `$`]): ref ConfigurationParseError =
   new result
   result.msg = format(msg, args)


proc `$`*(cfg: Configuration): string =
   const INDENT = 2
   if len(cfg.include_paths) > 0:
      add(result, "Include paths:\n")
   for i, path in cfg.include_paths:
      add(result, indent(format("$1: $2", i, path), INDENT) & "\n")

   if len(cfg.defines) > 0:
      add(result, "Defines:\n")
   for i, define in cfg.defines:
      add(result, indent(format("$1: $2", i, define), INDENT) & "\n")

   add(result, "Maximum number of diagnostic messages: ")
   if cfg.max_nof_diagnostics < 0:
      add(result, "unlimited")
   else:
      add(result, $cfg.max_nof_diagnostics)


proc init*(cfg: var Configuration) =
   set_len(cfg.include_paths, 0)
   set_len(cfg.defines, 0)
   cfg.max_nof_diagnostics = -1
   cfg.diagnostics.undeclared_identifiers = true
   cfg.diagnostics.unconnected_ports = true
   cfg.diagnostics.missing_ports = true


proc find_configuration_file*(path: string): string =
   const FILENAMES = [".vl.toml", "vl.toml", ".vl/.vl.toml", ".vl/vl.toml",
                      "vl/.vl.toml", "vl/vl.toml"]
   var expanded_path = ""
   try:
      expanded_path = expand_filename(path)
   except OSError:
      return ""

   # Walk from the provided path up to the root directory, searching for a
   # configuration file.
   for p in parent_dirs(expanded_path, false, true):
      for filename in FILENAMES:
         let tmp = p / filename
         if file_exists(tmp):
            return tmp


template ensure_array(t: TomlValueRef, scope: string) =
   if t.kind != TomlValueKind.Array:
      raise new_configuration_parse_error("An array is expected for value '$1'.", scope)


template ensure_string(t: TomlValueRef, scope: string) =
   if t.kind != TomlValueKind.String:
      raise new_configuration_parse_error("Expected a string when parsing '$1'.", scope)


template ensure_int(t: TomlValueRef, scope: string) =
   if t.kind != TomlValueKind.Int:
      raise new_configuration_parse_error("Expected an integer when parsing '$1'.", scope)


template ensure_bool(t: TomlValueRef, scope: string) =
   if t.kind != TomlValueKind.Bool:
      raise new_configuration_parse_error("Expected a boolean value when parsing '$1'.", scope)


proc parse_verilog_table(t: TomlValueRef, cfg: var Configuration) =
   if has_key(t, "include_paths"):
      let include_paths = t["include_paths"]
      ensure_array(include_paths, "verilog.include_paths")
      for val in get_elems(include_paths):
         ensure_string(val, "verilog.include_paths")
         let path_to_add = strip(get_str(val))
         if path_to_add notin cfg.include_paths:
            add(cfg.include_paths, path_to_add)

   if has_key(t, "defines"):
      let defines = t["defines"]
      ensure_array(defines, "verilog.defines")
      for val in get_elems(defines):
         ensure_string(val, "verilog.defines")
         add(cfg.defines, get_str(val))


proc parse_vls_table(t: TomlValueRef, cfg: var Configuration) =
   if has_key(t, "max_nof_diagnostics"):
      let val = t["max_nof_diagnostics"]
      ensure_int(val, "vls.max_nof_diagnostics")
      cfg.max_nof_diagnostics = get_int(val)


proc parse_diagnostics_table(t: TomlValueRef, cfg: var Configuration) =
   if has_key(t, "undeclared_identifiers"):
      let val = t["undeclared_identifiers"]
      ensure_bool(val, "diagnostics.undeclared_identifiers")
      cfg.diagnostics.undeclared_identifiers = get_bool(val)

   if has_key(t, "unconnected_ports"):
      let val = t["unconnected_ports"]
      ensure_bool(val, "diagnostics.unconnected_ports")
      cfg.diagnostics.unconnected_ports = get_bool(val)

   if has_key(t, "missing_ports"):
      let val = t["missing_ports"]
      ensure_bool(val, "diagnostics.missing_ports")
      cfg.diagnostics.missing_ports = get_bool(val)


proc parse(t: TomlValueRef): Configuration =
   init(result)
   if has_key(t, "verilog"):
      parse_verilog_table(t["verilog"], result)

   if has_key(t, "vls"):
      parse_vls_table(t["vls"], result)

   if has_key(t, "diagnostics"):
      parse_diagnostics_table(t["diagnostics"], result)


proc parse_string*(s: string): Configuration =
   # Used by the test framework.
   try:
      result = parse(parsetoml.parse_string(s))
   except TomlError:
      raise new_configuration_parse_error(
         "Error while parsing configuration from a string.")


proc parse_file*(filename: string): Configuration =
   if not file_exists(filename):
      raise new_configuration_parse_error("The file '$1' does not exist.", filename)

   let lfilename = expand_filename(filename)
   try:
      result = parse(parsetoml.parse_file(lfilename))
      # When we're parsing a file, any
      let parent_dir = parent_dir(lfilename)
      for path in mitems(result.include_paths):
         if not is_absolute(path):
            path = join_path(parent_dir, path)
   except TomlError:
      raise new_configuration_parse_error(
         "Error while parsing configuration file '$1'.", lfilename)


proc get_configuration_for_source_file*(filename: string): Configuration =
   ## Search for a configuration file for the source file ``filename``. If a file
   ## is found but the parsing fails, the returned object will contain the
   ## default values.
   let cfg_filename = find_configuration_file(filename)
   init(result)
   if len(cfg_filename) > 0:
      try:
         result = parse_file(cfg_filename)
      except ConfigurationParseError:
         discard
