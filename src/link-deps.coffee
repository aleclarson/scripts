
fs = require "io/sync"
exec = require "exec"
path = require "path"
sync = require "sync"

GLOBAL_NODE_MODULES = path.join process.env.HOME, "lib/node_modules"

moduleName = process.argv[2]
manifestPath = path.join process.cwd(), moduleName, "manifest.json"
if not fs.exists manifestPath
  console.warn "Must read dependencies first: 'scripts read-deps [package]'"
  process.exit 0

manifest = require manifestPath

manifest[moduleName] =
  path: path.join process.cwd(), moduleName
  version: "aleclarson/"
  dependers: []

timeStart = Date.now()
sync.each manifest, (moduleJson, moduleName) ->
  globalPath = path.join GLOBAL_NODE_MODULES, moduleName

  sync.each moduleJson.dependers, (depender) ->
    depJson = manifest[depender]
    return if depJson.remote
    return unless depJson.version.startsWith "aleclarson/"

    installedPath = path.join depJson.path, "node_modules", moduleName
    return if fs.exists installedPath

    # Ensure the 'node_modules' dir exists.
    fs.makeDir depJson.path + "/node_modules"

    console.log "\nLinking:\n#{installedPath}\n  -> #{globalPath}\n"
    exec.sync "ln -s #{globalPath} #{installedPath}"
    return

timeEnd = Date.now()
console.log "Linked local dependencies (in #{timeEnd - timeStart} ms)"
