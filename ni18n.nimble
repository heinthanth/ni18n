version       = "0.1.0"
author        = "Hein Thant Maung Maung"
description   = "Super Fast Nim Macros For Internationalization and Localization"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]

requires "nim >= 1.0.0"

import strutils, os

proc generateIndexHtml() =
    let p = projectName()
    mvFile(p & ".html", "index.html")
    let sedOption = if buildOS == "linux": "-i" else: "-i ''"
    for file in walkDirRec(".", {pcFile}):
        exec "sed $# 's/$#.html/index.html/g' $#" % [sedOption, p, file]

task docs, "Generate API documentation":
    let hash = getEnv("GITHUB_SHA")
    let repo = "https://github.com/heinthanth/ni18n"
    exec "nimble doc --project --index:on --git.url:'$repo' $commit --outdir:docs src/ni18n.nim" % ["repo", repo, "commit", if hash == "": "" else: "--git.commit:" & hash]
    withDir "docs": generateIndexHtml()
