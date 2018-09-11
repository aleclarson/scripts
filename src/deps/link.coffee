
{resolveModule} = require "resolve"

path = require "path"
exec = require "exec"
log = require "log"
fs = require "fsx"

searchGlobalPaths = require "../utils/searchGlobalPaths"

npmBin = exec.sync "npm bin -g"
npmRoot = exec.sync "npm root -g"

{red, green, yellow} = log.color

module.exports = (args) ->

  if args._.length
    args._.forEach (moduleName) ->
      createLocalLink moduleName, args
    return

  modulePath =
    if moduleName = args._[0]
    then path.resolve moduleName
    else process.cwd()

  if args.g or args.global
    createGlobalLink modulePath, args
    return

  createLocalLinks modulePath, args
  return

createLink = (linkPath, targetPath, args) ->

  # Symlink all children of the linked directory.
  if args.hard
    log.moat 1
    log.white """
      Hard linking: #{green linkPath}
           to path: #{yellow targetPath}
    """
    log.moat 1
    fs.writeDir linkPath
    fs.readDir(targetPath).forEach (name) ->
      return if /^\.git/.test name
      filePath = path.join targetPath, name
      fs.writeLink path.join(linkPath, name), filePath
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

createLocalLink = (moduleName, args) ->

  linkPath = path.resolve "node_modules", moduleName
  if fs.exists linkPath
    if !args.f
      log.warn "Link path already exists: #{green linkPath}"
      return
    removePath linkPath

  if !targetPath = searchGlobalPaths moduleName
    log.warn "Global dependency does not exist: #{green moduleName}"
    return

  createLink linkPath, targetPath, args

createGlobalLink = (modulePath, args) ->

  jsonPath = path.join modulePath, "package.json"
  return if !fs.isFile jsonPath
  json = require jsonPath

  linkPath = path.join npmRoot, json.name
  if fs.exists linkPath
    if !args.f
      log.warn "Link path already exists: #{green linkPath}"
      return
    removePath linkPath
  createLink linkPath, modulePath, args

  return if !bin = json.bin
  if typeof bin == "string"
    bin = { [json.name]: bin }

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
    fs.chmod binPath, "755"
  return

createLocalLinks = (modulePath, args) ->

  jsonPath = path.join modulePath, "package.json"
  return if !fs.isFile jsonPath

  json = require jsonPath
  deps = json.dependencies
  return if !deps

  for name, version of deps
    linkPath = path.join modulePath, "node_modules", name
    continue if fs.exists linkPath

    if version.startsWith "file:"
      globalPath = path.resolve modulePath, version.slice 5
      if !fs.exists globalPath
        log.warn "Local dependency does not exist: #{green globalPath}"
        continue

    else if !globalPath = searchGlobalPaths name
      log.warn "Global dependency does not exist: #{green globalPath}"
      continue

    if fs.isLink linkPath
      try fs.stat linkPath
      catch err
        if err.code == "ENOENT"
          fs.removeFile linkPath
          log.moat 1
          log.white "Removing broken symlink: #{red name}"
          log.moat 1

    createLink linkPath, globalPath, args

removePath = (path) ->
  if fs.isDir path
  then fs.removeDir path
  else fs.removeFile path
