
SortedArray = require "sorted-array"
path = require "path"
git = require "git-utils"
fs = require "io/sync"

module.exports = (args) ->
  dirty = []

  Promise.all fs.readDir("."), (mod) ->
    return if not fs.isDir mod
    return if not git.isRepo mod
    git.isClean(mod).then (isClean) ->
      return if isClean
      jsonPath = path.join mod, "package.json"
      try json = JSON.parse fs.read jsonPath
      json and dirty.push {name: mod, deps: json.dependencies}

  .then ->

    sorted = SortedArray dirty, (a, b) ->
      if a.deps and a.deps[b.name]
      then 1 else -1

    sorted.array.forEach (mod) ->
      log.moat 1
      log.white mod.name
      log.plusIndent 2
      for dep in dirty
        continue if not dep.deps?[mod.name]
        log.moat 0
        log.gray dep.name
      log.popIndent()
      log.moat 1
