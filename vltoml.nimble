version = "0.1.0"
author = "Marcus Eriksson"
description = "The configuration file parser for the vls and vlint packages."
src_dir = "src"
license = "MIT"

skip_dirs = @["tests"]

requires "nim >= 1.2.6"
requires "parsetoml >= 0.5.0"

task test, "Run the test suite":
   with_dir("tests"):
      exec("nim c --hints:off -r tconfiguration")
