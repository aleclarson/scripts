
AsyncTaskGroup = require "AsyncTaskGroup"
OneOf = require "OneOf"
git = require "git-utils"

getInverseDependencies = require "../utils/getInverseDependencies"
sortModules = require "../utils/sortModules"
readModules = require "../utils/readModules"

config = require "../../config.json"
ignored = OneOf config.ignore

module.exports = (args) ->

  dirty = Object.create null

  log.moat 1
  log.gray "Finding modules with uncommitted changes..."
  log.moat 1
  log.flush()

  mods = readModules process.cwd(), (file, json) ->
    git.isRepo(file) and not ignored.test(json.name)

  tasks = AsyncTaskGroup {maxConcurrent: 20}
  tasks.map Object.keys(mods), (name) ->
    {file, json} = mods[name]
    git.isClean file
    .then (isClean) ->
      isClean or dirty[name] = {file, json}

  .then ->
    log.moat 1
    log.gray "Sorting modules..."
    log.moat 1
    log.flush()

    sortedKeys = Object.create null
    sorted = sortModules dirty, ({json}) ->
      for dep, _ of json.dependencies
        continue if not dirty[dep]
        return no if not sortedKeys[dep]
      sortedKeys[json.name] = yes
      return yes

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
