
path = require "path"
exec = require "exec"
fs = require "io/sync"

npmRoot = exec.sync "npm root -g"

module.exports = (args) ->
  [moduleName] = args._

  if not moduleName
    log.warn "'link-dep' must be passed a module name!"
    return

  if args.g or args.global
    linkPath = path.join npmRoot, moduleName
    targetPath = path.join process.cwd(), moduleName
  else
    linkPath = path.join process.cwd(), "node_modules", moduleName
    targetPath = path.join npmRoot, moduleName

  if fs.exists linkPath
    log.warn "'linkPath' already exists:\n  #{linkPath}"
    return

  if not fs.exists targetPath
    log.warn "'targetPath' does not exist:\n  #{targetPath}"
    return

  {green} = log.color
  log.moat 1
  log.white """
    Linking:
      #{green linkPath}
      -> #{targetPath}
  """
  log.moat 1

  fs.writeLink linkPath, targetPath
  return
