
{resolveModule} = require "resolve"

isType = require "isType"
path = require "path"
exec = require "exec"
sync = require "sync"
fs = require "io/sync"

npmBin = exec.sync "npm bin -g"
npmRoot = exec.sync "npm root -g"

{red, green, yellow} = log.color

module.exports = (args) ->

  modulePath =
    if moduleName = args._[0]
    then path.resolve moduleName
    else process.cwd()

  if args.g or args.global
    createGlobalLink modulePath, args
  else if args._.length
    createLocalLink modulePath, args
  else
    createLocalLinks modulePath, args
  return

createLink = (linkPath, targetPath, args) ->

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
    Creating symlink..
      #{green linkPath}
    ..that points to:
      #{yellow targetPath}
  """
  log.moat 1

  fs.writeDir path.dirname linkPath
  fs.writeLink linkPath, targetPath
  return

createLocalLink = (modulePath, args) ->
  moduleName = path.basename modulePath
  linkPath = path.resolve "node_modules", moduleName
  targetPath = path.join npmRoot, moduleName
  createLink linkPath, targetPath, args

createGlobalLink = (modulePath, args) ->

  moduleName = path.basename modulePath
  linkPath = path.join npmRoot, moduleName
  createLink linkPath, modulePath, args

  jsonPath = path.join modulePath, "package.json"
  return unless fs.isFile jsonPath

  json = require jsonPath
  return unless isType json.bin, Object

  for scriptName, scriptPath of json.bin
    scriptPath = path.resolve modulePath, scriptPath
    binPath = path.join npmBin, scriptName
    log.moat 1
    log.white """
      Creating symlink..
        #{green binPath}
      ..that points to:
        #{yellow scriptPath}
    """
    log.moat 1
    fs.writeLink binPath, scriptPath
    fs.setMode binPath, "755"
  return

createLocalLinks = (modulePath, args) ->

  jsonPath = path.join modulePath, "package.json"
  return unless fs.isFile jsonPath

  json = require jsonPath
  deps = json.dependencies
  return unless isType deps, Object

  gitRegex = /[^\/]+\/[^\#]+(\#.+)?/g

  for name, version of deps
    isGit = gitRegex.test version

    unless dep = resolveModule name, modulePath
      log.warn "Cannot resolve dependency: #{green name} #{yellow version}"
      continue

    globalPath = path.join npmRoot, name
    unless fs.exists globalPath
      log.warn "Global dependency does not exist: #{green globalPath}"
      continue

    linkPath = path.join modulePath, "node_modules", name
    if fs.exists linkPath
      continue unless fs.isLink linkPath
      continue unless fs.isLinkBroken linkPath
      fs.remove linkPath
      log.moat 1
      log.white "Removing broken symlink: #{red name}"
      log.moat 1

    createLink linkPath, globalPath, args
