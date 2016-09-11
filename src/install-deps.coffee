
fs = require "io/sync"
exec = require "exec"
path = require "path"
sync = require "sync"

moduleName = process.argv[2]
manifestPath = path.join process.cwd(), moduleName, "manifest.json"
if not fs.exists manifestPath
  console.warn "Must read dependencies first: 'scripts read-deps [package]'"
  process.exit 0

timeStart = Date.now()

manifest = require manifestPath
sync.each manifest, (moduleJson, moduleName) ->
  return if not moduleJson.remote
  sync.each moduleJson.dependers, (depender) ->
    depPath = path.join process.cwd(), depender
    installedPath = path.join depPath, "node_modules", moduleName
    if not fs.exists installedPath
      console.log "\nInstalling:\n#{moduleName}\n  -> #{depPath}/node_modules/#{moduleName}\n"
      try exec.sync "npm install #{moduleName}", cwd: depPath
      catch error
         throw error unless /WARN/.test error.message
    return

timeEnd = Date.now()
console.log "Installed remote dependencies (in #{timeEnd - timeStart} ms)"
