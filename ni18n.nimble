version       = "0.1.0"
author        = "Hein Thant Maung Maung"
description   = "Super Fast Nim Macros For Internationalization and Localization"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]

requires "nim >= 1.6.10"

import strutils

task docs, "Generate API documentation":
    let hash = getEnv("GITHUB_SHA")
    let repo = "https://github.com/heinthanth/ni18n"
    exec "nimble doc --project --index:on --git.url:'$repo' --git.commit:'$hash' --outdir:docs src/ni18n.nim" % ["repo", repo, "hash", hash]
