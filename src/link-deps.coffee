
fs = require "io/sync"
exec = require "exec"
path = require "path"
sync = require "sync"

module.exports = (args) ->

  if moduleName = args._[0]
    modulePath = path.join process.cwd(), moduleName
  else
    modulePath = process.cwd()
    moduleName = path.basename modulePath

  manifestPath = path.join modulePath, "manifest.json"
  if fs.exists manifestPath
    manifest = require manifestPath
  else
    log.warn "'link-deps' uses the manifest, please call 'read-deps' first!"
    return

  manifest[modulePath] = dependers: []

  if args.refresh
    sync.each manifest, (depJson, depPath) ->
      return if not path.isAbsolute depPath
      moduleDeps = path.join depPath, "node_modules"

      log.moat 1
      log.white """
        Refreshing:
          #{moduleDeps}
      """
      log.moat 1

      fs.match moduleDeps + "/*"
        .forEach (filePath) ->
          if fs.isLink filePath
            fs.remove filePath
          return

  npmRoot = exec.sync "npm root -g"
  sync.each manifest, (depJson, depPath) ->

    return if not path.isAbsolute depPath
    depName = path.basename depPath

    globalPath = path.join npmRoot, depName
    return if not fs.exists globalPath

    sync.each depJson.dependers, (parentPath) ->
      return if not path.isAbsolute parentPath

      installedPath = path.join parentPath, "node_modules", depName
      if fs.exists installedPath
        return if not fs.isLink installedPath
        return if not fs.isLinkBroken installedPath

      # Ensure the 'node_modules' dir exists.
      fs.writeDir parentPath + "/node_modules"

      log.moat 1
      log.white """
        Linking:
          #{installedPath}
          -> #{globalPath}
      """
      log.moat 1

      fs.writeLink installedPath, globalPath
      return
