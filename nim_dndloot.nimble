# Package

version       = "0.1.0"
author        = "RosGus80"
description   = "A package for a dnd random loot generator "
license       = "MIT"
srcDir        = "src"
binDir        = "bin"
bin           = @["nim_dndloot", "main_cli"]


# Dependencies

requires "nim >= 2.2.0"
requires "cligen"
