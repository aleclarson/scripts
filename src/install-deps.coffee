
fs = require "io/sync"
exec = require "exec"
path = require "path"
sync = require "sync"

module.exports = (args) ->
  moduleName = args._[0] or path.basename process.cwd()

  manifestPath = path.join process.cwd(), moduleName, "manifest.json"
  if fs.exists manifestPath
    manifest = require manifestPath
  else
    log.warn "'install-deps' uses the manifest, please call 'read-deps' first!"
    return

  manifest = require manifestPath
  sync.each manifest, (moduleJson, moduleName) ->
    return if not moduleJson.remote
    sync.each moduleJson.dependers, (depender) ->
      depPath = path.join process.cwd(), depender
      installedPath = path.join depPath, "node_modules", moduleName
      if not fs.exists installedPath
        log.moat 1
        log.white """
          Installing:
            #{moduleName}
            -> #{depPath}/node_modules/#{moduleName}
        """
        log.moat 1
        try exec.sync "npm install #{moduleName}", cwd: depPath
        catch error
           throw error unless /WARN/.test error.message
      return
