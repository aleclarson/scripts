
OneOf = require "OneOf"
path = require "path"
exec = require "exec"
git = require "git-utils"
fs = require "io/sync"

inverseSort = require "../utils/inverseSort"

config = require "../../config.json"
config.ignore = OneOf config.ignore

module.exports = (args) ->
  outdated = Object.create null

  files = fs.readDir "."
  inverseSort files, (file) ->
    return if config.ignore.test file
    return if not fs.isDir file
    return if not git.isRepo file

    filePath = path.resolve file
    Promise.all [
      git.isClean filePath
      git.hasBranch filePath, "unstable"
    ]

    .then ([ isClean, hasBranch ]) ->
      return unless isClean and hasBranch
      stdout = exec.sync "git diff --name-status master unstable", cwd: filePath
      return stdout.length > 0

  .then (pkgs) ->
    for pkg, index in pkgs
      log.moat 1
      log.white pkg.name
      log.gray.dim " (#{index})"
      log.plusIndent 2
      for dep in pkgs
        continue if not dep.deps[pkg.name]
        log.moat 0
        log.gray dep.name
      log.popIndent()
      log.moat 1
    return
