
# 1. Get clean repos.
# 2. Check if master branch is even with unstable branch.
# 3. Print repos with outdated master branch.

require "LazyVar"
require "Event"

Promise = require "Promise"
OneOf = require "OneOf"
path = require "path"
exec = require "exec"
git = require "git-utils"
log = require "log"
fs = require "fsx"

files = fs.readDir process.cwd()

ignoredModules = OneOf [
  "react-native"
  "immutable"
]

global.filesPromise =
Promise.chain files, (file) ->
  return if ignoredModules.test file
  filePath = path.resolve file
  gitPath = path.resolve file, ".git"
  return if not fs.isDir gitPath
  Promise.all [
    git.isClean filePath
    git.hasBranch filePath, "unstable"
  ]
  .then ([ isClean, hasBranch ]) ->
    return unless isClean and hasBranch
    log.moat 1
    log.it file
    results = exec.sync "git diff --name-status master unstable", cwd: filePath
    if results.length
      log.moat 1
      log.it results
    log.moat 1
    return
