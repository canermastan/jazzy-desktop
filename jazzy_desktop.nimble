# Package

version       = "0.1.0"
author        = "Caner"
description   = "Jazzy Desktop Framework Prototype"
license       = "MIT"
srcDir        = "src"
installDirs   = @["jazzy_desktop", "cli"]
installExt    = @["nim", "cpp", "c", "h"]
bin           = @["jazzyd"]


# Dependencies

requires "nim >= 2.0.0"
requires "jazzy >= 0.4.4"
requires "webview"
