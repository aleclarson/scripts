
fs = require "io/sync"
exec = require "exec"
path = require "path"
sync = require "sync"
isType = require "isType"

GLOBAL_NODE_MODULES = path.join process.env.HOME, "lib/node_modules"

deps = Object.create null
readDeps = (modulePath, fromModuleName) ->

  moduleName = path.basename modulePath
  if moduleJson = deps[moduleName]
    fromModuleName and moduleJson.dependers.add fromModuleName
    return

  pkgJson = modulePath + "/package.json"
  if not fs.isFile pkgJson
    deps[moduleName] =
      remote: yes
      dependers: new Set [fromModuleName]
    return

  pkgJson = require pkgJson
  if fromModuleName

    globalPath = path.join GLOBAL_NODE_MODULES, moduleName
    if not fs.exists globalPath
      console.log "\nLinking:\n#{globalPath}\n  -> #{modulePath}\n"
      exec.sync "sudo ln -s #{modulePath} #{globalPath}"

    deps[moduleName] =
      path: modulePath
      version: pkgJson.version
      dependers: new Set [fromModuleName]

  if pkgJson and isType pkgJson.dependencies, Object
    sync.each pkgJson.dependencies, (version, name) ->
      depPath = path.join process.cwd(), name
      readDeps depPath, moduleName
      return
  return

timeStart = Date.now()
readDeps entryPath = path.join process.cwd(), process.argv[2]
timeEnd = Date.now()
console.log "\nFound #{Object.keys(deps).length} dependencies (in #{timeEnd - timeStart} ms)\n"

# Convert sets to arrays (for JSON.stringify)
sync.each deps, (moduleJson, moduleName) ->
  moduleJson.dependers = Array.from moduleJson.dependers
  return

manifest = JSON.stringify deps, null, 2
fs.write entryPath + "/manifest.json", manifest
