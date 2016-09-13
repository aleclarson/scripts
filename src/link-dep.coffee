
path = require "path"
exec = require "exec"
fs = require "io/sync"

module.exports = (args) ->
  [moduleName] = args._

  if not moduleName
    log.warn "'link-dep' must be passed a module name!"
    return

  if args.g or args.global
    npmRoot = exec.sync "npm root -g"
    linkPath = path.join npmRoot, moduleName
    targetPath = path.join process.cwd(), moduleName
    fs.writeLink linkPath, targetPath
    log.moat 1
    log.white """
      Linking:
        #{linkPath}
        -> #{targetPath}
    """
    log.moat 1
    return

  log.warn "'link-dep' without the '-g' flag is not yet supported!"
  return
