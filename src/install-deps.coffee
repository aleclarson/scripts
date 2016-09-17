
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

  sync.each manifest, (depJson, depPath) ->
    return if not path.isAbsolute depPath
    depName = path.basename depPath
    sync.each depJson.dependers, (parentPath) ->
      return if not path.isAbsolute parentPath
      installedPath = path.join parentPath, "node_modules", depName
      if not fs.exists installedPath
        log.moat 1
        log.white """
          Installing:
            #{depName}
            -> #{parentPath}/node_modules/#{depName}
        """
        log.moat 1
        try exec.sync "npm install #{depName}", cwd: parentPath
        catch error
           throw error unless /WARN/.test error.message
      return
