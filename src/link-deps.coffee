
fs = require "io/sync"
exec = require "exec"
path = require "path"
sync = require "sync"
minimist = require "minimist"

moduleName = process.argv[2]
manifestPath = path.join process.cwd(), moduleName, "manifest.json"
if not fs.exists manifestPath
  console.warn "Must read dependencies first: 'scripts read-deps [package]'"
  process.exit 0

manifest = require manifestPath

manifest[moduleName] =
  path: path.join process.cwd(), moduleName
  dependers: []

args = minimist process.argv.slice 2

if args.refresh
  sync.each manifest, (moduleJson) ->
    return if moduleJson.remote
    moduleDeps = path.join moduleJson.path, "node_modules"
    console.log "\nRefreshing:\n#{moduleDeps}\n"
    fs.match moduleDeps + "/*"
      .forEach (filePath) ->
        if fs.isLink filePath
          fs.remove filePath
        return

timeStart = Date.now()
sync.each manifest, (moduleJson, moduleName) ->
  globalPath = path.join process.env.HOME, "lib/node_modules", moduleName
  return if not fs.exists globalPath

  sync.each moduleJson.dependers, (depender) ->
    depJson = manifest[depender]
    return if depJson.remote

    installedPath = path.join depJson.path, "node_modules", moduleName
    return if fs.exists installedPath

    # Ensure the 'node_modules' dir exists.
    fs.makeDir depJson.path + "/node_modules"

    console.log "\nLinking:\n#{installedPath}\n  -> #{globalPath}\n"
    exec.sync "ln -s #{globalPath} #{installedPath}"
    return

timeEnd = Date.now()
console.log "Linked local dependencies (in #{timeEnd - timeStart} ms)"
