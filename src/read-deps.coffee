
fs = require "io/sync"
exec = require "exec"
path = require "path"
sync = require "sync"

module.exports = (args) ->

  entryPath =
    if args._.length
    then path.resolve args._[0]
    else process.cwd()

  readDeps entryPath

  log.moat 1
  log.white "Found #{Object.keys(deps).length} dependencies!"
  log.moat 1

  # Convert sets to arrays (for JSON.stringify)
  sync.each deps, (moduleJson, moduleName) ->
    moduleJson.dependers = Array.from moduleJson.dependers
    return

  manifest = JSON.stringify deps, null, 2
  fs.write entryPath + "/manifest.json", manifest

#
# Helpers
#

npmRoot = exec.sync "npm root -g"

# Protect against miscapitalized module names.
lowercased = Object.create null

shouldLink = (linkPath) ->
  if fs.isLink linkPath
  then fs.isLinkBroken linkPath
  else yes

deps = Object.create null
readDeps = (modulePath, fromModuleName) ->

  moduleName = path.basename modulePath
  if moduleJson = deps[moduleName]
    fromModuleName and moduleJson.dependers.add fromModuleName
    return

  moduleHash = moduleName.toLowerCase()
  collision = lowercased[moduleHash]
  if collision and collision.to isnt moduleName
    log.warn """
      Possibly incorrect capitalization:
        {from: #{fromModuleName}, to: #{moduleName}}

      This module is also required with a similar name:
        {from: #{collision.from}, to: #{collision.to}}
    """
    return

  lowercased[moduleHash] = {from: fromModuleName, to: moduleName}

  pkgJson = modulePath + "/package.json"
  if not fs.isFile pkgJson
    deps[moduleName] =
      remote: yes
      dependers: new Set [fromModuleName]
    return

  pkgJson = require pkgJson
  if fromModuleName

    globalPath = path.join npmRoot, moduleName
    if shouldLink globalPath
      log.moat 1
      log """
        Linking:
          #{globalPath}
          -> #{modulePath}
      """
      log.moat 1
      fs.writeLink globalPath, modulePath

    deps[moduleName] =
      path: modulePath
      dependers: new Set [fromModuleName]

  if pkgJson and pkgJson.dependencies
    sync.each pkgJson.dependencies, (version, name) ->
      depPath = path.join process.cwd(), name
      readDeps depPath, moduleName
      return
  return
