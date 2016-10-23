
isType = require "isType"
path = require "path"
exec = require "exec"
sync = require "sync"
fs = require "io/sync"

npmBin = exec.sync "npm bin -g"
npmRoot = exec.sync "npm root -g"

module.exports = (args) ->
  {green} = log.color

  if args.g or args.global

    if moduleName = args._[0]
      targetPath = path.resolve moduleName
    else
      targetPath = process.cwd()
      moduleName = path.basename targetPath

    linkPath = path.join npmRoot, moduleName

    jsonPath = path.join targetPath, "package.json"
    if fs.isFile jsonPath
      json = fs.read jsonPath
      json = JSON.parse json
      if isType json.bin, Object
        sync.each json.bin, (scriptPath, scriptName) ->
          scriptPath = path.resolve targetPath, scriptPath
          binPath = path.join npmBin, scriptName
          log.moat 1
          log.white """
            Linking:
              #{green binPath}
              -> #{scriptPath}
          """
          log.moat 1
          fs.writeLink binPath, scriptPath
          fs.setMode binPath, "755"

  else
    moduleName = args._[0]
    if not moduleName
      log.warn "Must provide a module name!"
      return

    linkPath = path.resolve "node_modules", moduleName
    targetPath = path.join npmRoot, moduleName

  if not fs.exists targetPath
    log.warn "'targetPath' does not exist:\n  #{targetPath}"
    return

  if fs.exists linkPath

    if args.f
      fs.remove linkPath

    else
      log.warn "'linkPath' already exists:\n  #{linkPath}"
      return

  log.moat 1
  log.white """
    Linking:
      #{green linkPath}
      -> #{targetPath}
  """
  log.moat 1

  fs.writeDir path.dirname linkPath
  fs.writeLink linkPath, targetPath
  return

# fs = require "io/sync"
# exec = require "exec"
# path = require "path"
# sync = require "sync"
#
# module.exports = (args) ->
#
#   modulePath =
#     if args._.length
#     then path.resolve args._[0]
#     else process.cwd()
#
#   manifestPath = path.join modulePath, "manifest.json"
#   if fs.exists manifestPath
#     manifest = require manifestPath
#   else
#     log.warn "'link-deps' uses the manifest, please call 'read-deps' first!"
#     return
#
#   manifest[modulePath] = dependers: []
#
#   if args.refresh
#     sync.each manifest, (depJson, depPath) ->
#       return if not path.isAbsolute depPath
#       moduleDeps = path.join depPath, "node_modules"
#
#       log.moat 1
#       log.white """
#         Refreshing:
#           #{moduleDeps}
#       """
#       log.moat 1
#
#       fs.match moduleDeps + "/*"
#         .forEach (filePath) ->
#           if fs.isLink filePath
#             fs.remove filePath
#           return
#
#   npmRoot = exec.sync "npm root -g"
#   sync.each manifest, (depJson, depPath) ->
#
#     return if not path.isAbsolute depPath
#     depName = path.basename depPath
#
#     globalPath = path.join npmRoot, depName
#     return if not fs.exists globalPath
#
#     sync.each depJson.dependers, (parentPath) ->
#       installedPath = path.join parentPath, "node_modules", depName
#       if fs.exists installedPath
#         return if not fs.isLink installedPath
#         return if not fs.isLinkBroken installedPath
#
#       log.moat 1
#       log.white """
#         Linking:
#           #{installedPath}
#           -> #{globalPath}
#       """
#       log.moat 1
#
#       fs.writeDir path.dirname installedPath
#       fs.writeLink installedPath, globalPath
#       return
