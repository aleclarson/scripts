
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
