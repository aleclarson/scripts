
git = require "git-utils"
fs = require "io/sync"

inverseSort = require "../utils/inverseSort"

module.exports = (args) ->
  files = fs.readDir "."
  inverseSort files, (file) ->
    return if not fs.isDir file
    return if not git.isRepo file
    git.isClean(file).then (clean) -> not clean

  .then (pkgs) ->
    for pkg, index in pkgs
      log.moat 1
      log.white pkg.name
      log.plusIndent 2
      for dep in pkgs
        continue if not dep.deps[pkg.name]
        log.moat 0
        log.gray dep.name
      log.popIndent()
      log.moat 1
    return
