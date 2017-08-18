
# TODO: Find which modules depend on a specific version.

hasKeys = require "hasKeys"

readModules = require "../utils/readModules"

module.exports = (args) ->
  moduleName = args._.shift()

  deps = Object.create null
  mods = readModules process.cwd()
  for name, mod of mods
    {dependencies} = mod.json
    continue unless dependencies
    if version = dependencies[moduleName]
      if 0 <= version.indexOf "#"
        version = version.split("#").pop()
      deps[name] = version

  log.moat 1
  log.white "Modules that depend on "
  log.green moduleName
  log.moat 1
  log.plusIndent 2

  unless hasKeys deps
    log.gray "No modules were found."
    log.moat 1
    return

  for name, version of deps
    log.white name + " "
    log.yellow version
    log.moat 1
  return
