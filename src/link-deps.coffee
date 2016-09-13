
fs = require "io/sync"
exec = require "exec"
path = require "path"
sync = require "sync"

module.exports = (args) ->

  moduleName = args._[0]
  manifestPath = path.join process.cwd(), moduleName, "manifest.json"
  if not fs.exists manifestPath
    log.warn "Must read dependencies first: 'scripts read-deps [package]'"
    return

  manifest = require manifestPath

  manifest[moduleName] =
    path: path.join process.cwd(), moduleName
    dependers: []

  if args.refresh
    sync.each manifest, (moduleJson) ->
      return if moduleJson.remote
      moduleDeps = path.join moduleJson.path, "node_modules"

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
  sync.each manifest, (moduleJson, moduleName) ->
    globalPath = path.join npmRoot, moduleName
    return if not fs.exists globalPath

    sync.each moduleJson.dependers, (depender) ->
      depJson = manifest[depender]
      return if depJson.remote

      installedPath = path.join depJson.path, "node_modules", moduleName
      if fs.exists installedPath
        return if not fs.isLink installedPath
        return if not fs.isLinkBroken installedPath

      # Ensure the 'node_modules' dir exists.
      fs.writeDir depJson.path + "/node_modules"

      log.moat 1
      log.white """
        Linking:
          #{installedPath}
          -> #{globalPath}
      """
      log.moat 1

      fs.writeLink installedPath, globalPath
      return
