
# TODO: Find which modules depend on a specific version.

hasKeys = require "hasKeys"

readModules = require "../utils/readModules"

module.exports = (args) ->
  moduleName = args._.shift()
  key =
    if args.dev
    then "devDependencies"
    else "dependencies"

  res = Object.create null
  mods = readModules process.cwd()
  for name, mod of mods
    deps = mod.json[key]
    continue unless deps
    if version = deps[moduleName]
      if 0 <= version.indexOf "#"
        version = version.split("#").pop()
      res[name] = version

  log.moat 1
  log.white "Modules that depend on "
  log.green moduleName
  log.moat 1
  log.plusIndent 2

  unless hasKeys res
    log.gray "No modules were found."
    log.moat 1
    return

  for name, version of res
    log.white name + " "
    log.yellow version
    log.moat 1
  return
