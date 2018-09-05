
AsyncTaskGroup = require "async-task-group"
git = require "git-utils"
fs = require "fsx"

getInverseDependencies = require "../utils/getInverseDependencies"
sortModules = require "../utils/sortModules"
readModules = require "../utils/readModules"

config = require "../../config.json"

module.exports = (args) ->

  dirty = Object.create null

  log.moat 1
  log.gray "Finding modules with uncommitted changes..."
  log.moat 1
  log.flush()

  mods = readModules process.cwd(), (file, json) ->
    fs.exists(file + "/.git") and !config.ignore.includes(json.name)

  tasks = new AsyncTaskGroup 20, (name) ->
    {file, json} = mods[name]
    if !await git.isClean file
      dirty[name] = {file, json}
      return

  tasks.concat Object.keys mods
  tasks.then ->
    log.moat 1
    log.gray "Sorting modules..."
    log.moat 1
    log.flush()

    sortedKeys = Object.create null
    sorted = sortModules dirty, ({json}) ->
      for dep, _ of json.dependencies
        continue if not dirty[dep]
        return false if not sortedKeys[dep]
      sortedKeys[json.name] = true
      return true

    sorted.forEach ({json}) ->
      log.moat 1
      log.white json.name
      log.plusIndent 2
      for dep, _ of json.dependencies
        continue if not dirty[dep]
        log.moat 0
        log.gray dep
      log.popIndent()
      log.moat 1
      log.flush()
    return
