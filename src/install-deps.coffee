
fs = require "io/sync"
exec = require "exec"
path = require "path"
sync = require "sync"

module.exports = (args) ->

  modulePath =
    if args._.length
    then path.resolve args._[0]
    else process.cwd()

  manifestPath = path.join modulePath, "manifest.json"
  if fs.exists manifestPath
    manifest = require manifestPath
  else
    log.warn "'install-deps' uses the manifest, please call 'read-deps' first!"
    return

  sync.each manifest, (depJson, depPath) ->
    return if path.isAbsolute depPath
    sync.each depJson.dependers, (parentPath) ->
      installedPath = path.join parentPath, "node_modules", depPath
      if fs.exists installedPath
        return if not args.refresh
        return if fs.isLink installedPath
        fs.remove installedPath
        {yellow} = log.color
        log.moat 1
        log.white """
          Reinstalling:
            #{yellow installedPath}
        """
        log.moat 1

      else
        {green} = log.color
        log.moat 1
        log.white """
          Installing:
            #{green installedPath}
        """
        log.moat 1

      try exec.sync "npm install #{depPath}", cwd: parentPath
      catch error
         throw error unless /WARN/.test error.message
      return
