
global.Promise = require "Promise"

prompt = require "prompt"
path = require "path"
exec = require "exec"
fs = require "io/sync"

module.exports = (args) ->

  unless moduleName = args._[0]
    return log.warn "Must provide a module name!"

  if moduleName[0] is "." or moduleName[0] is "/"
    return log.warn "Module names cannot start with . or /"

  log.moat 1
  log.red "Deleting package: "
  log.white moduleName
  log.moat 1
  log.gray "Are you sure?"
  shouldDestroy = prompt.sync {bool: yes}
  log.moat 1
  return unless shouldDestroy

  npmRoot = exec.sync "npm root -g"
  globalPath = path.join npmRoot, moduleName
  if fs.isLink globalPath
    dest = fs.readLink globalPath
    modulePath = path.resolve moduleName
    if dest is modulePath
      fs.remove globalPath

  fs.remove moduleName
