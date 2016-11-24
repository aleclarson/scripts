
AsyncTaskGroup = require "AsyncTaskGroup"
OneOf = require "OneOf"
exec = require "exec"
git = require "git-utils"

getInverseDependencies = require "../utils/getInverseDependencies"
sortModules = require "../utils/sortModules"
readModules = require "../utils/readModules"

config = require "../../config.json"
ignored = OneOf config.ignore

module.exports = (args) ->

  outdated = Object.create null

  log.moat 1
  log.gray "Finding modules with outdated master branches..."
  log.moat 1
  log.flush()

  mods = readModules process.cwd(), (file, json) ->
    git.isRepo(file) and not ignored.test(json.name)

  tasks = AsyncTaskGroup {maxConcurrent: 20}
  tasks.map Object.keys(mods), (name) ->
    {file, json} = mods[name]

    Promise.all [
      git.isClean file
      git.hasBranch file, "unstable"
    ]
    .then ([ isClean, hasBranch ]) ->
      return unless isClean and hasBranch
      exec.async "git diff --name-status master unstable", cwd: file
      .then (stdout) ->
        return if stdout.length is 0
        outdated[name] = {file, json}

  .then ->
    log.moat 1
    log.gray "Sorting modules..."
    log.moat 1
    log.flush()

    sortedKeys = Object.create null
    sorted = sortModules outdated, ({json}) ->
      for dep, _ of json.dependencies
        continue if not outdated[dep]
        return no if not sortedKeys[dep]
      sortedKeys[json.name] = yes
      return yes

    sorted.forEach ({json}) ->
      log.moat 1
      log.white json.name
      log.plusIndent 2
      for dep, _ of json.dependencies
        continue if not outdated[dep]
        log.moat 0
        log.gray dep
      log.popIndent()
      log.moat 1
      log.flush()
    return
