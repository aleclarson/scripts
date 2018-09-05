
AsyncTaskGroup = require "AsyncTaskGroup"
exec = require "exec"
git = require "git-utils"

getInverseDependencies = require "../utils/getInverseDependencies"
sortModules = require "../utils/sortModules"
readModules = require "../utils/readModules"

config = require "../../config.json"

module.exports = (args) ->

  outdated = Object.create null

  log.moat 1
  log.gray "Finding modules with outdated master branches..."
  log.moat 1
  log.flush()

  mods = readModules process.cwd(), (file, json) ->
    git.isRepo(file) and !config.ignore.includes(json.name)

  tasks = new AsyncTaskGroup 20, (name) ->
    {file, json} = mods[name]

    isClean = await git.isClean file
    hasBranch = await git.hasBranch file, "unstable"
    return unless isClean and hasBranch

    cmd = "git diff --name-status master unstable"
    stdout = await exec.async cmd, cwd: file
    if stdout.length
      outdated[name] = {file, json}
      return

  tasks.concat Object.keys mods
  tasks.then ->
    log.moat 1
    log.gray "Sorting modules..."
    log.moat 1
    log.flush()

    sortedKeys = Object.create null
    sorted = sortModules outdated, ({json}) ->
      for dep, _ of json.dependencies
        continue if not outdated[dep]
        return false if not sortedKeys[dep]
      sortedKeys[json.name] = true
      return true

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
