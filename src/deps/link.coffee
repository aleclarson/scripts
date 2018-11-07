{resolveModule} = require "resolve"

path = require "path"
exec = require "exec"
log = require "log"
fs = require "saxon/sync"

searchGlobalPaths = require "../utils/searchGlobalPaths"
readPackageJson = require "../utils/readPackageJson"

npmBin = exec.sync "npm bin -g"
npmRoot = exec.sync "npm root -g"

{red, green, yellow} = log.color

module.exports = (argv) ->

  if argv._.length
    argv._.forEach (name) ->
      createLocalLink name, argv
    return

  dir =
    if name = argv._[0]
    then path.resolve name
    else process.cwd()

  if argv.g or argv.global
    addGlobalPackage dir, argv
    return

  createLocalLinks dir, argv
  return

createLink = (linkPath, targetPath, argv) ->

  # Symlink all children of the linked directory.
  if argv.hard
    log.moat 1
    log.white """
      Hard linking: #{green linkPath}
           to path: #{yellow targetPath}
    """
    log.moat 1
    fs.mkdir linkPath
    fs.list(targetPath).forEach (name) ->
      return if /^\.git/.test name
      filePath = path.join targetPath, name
      fs.link path.join(linkPath, name), filePath
    return

  log.moat 1
  log.white """
    Creating symlink..
      #{green linkPath}
    ..that points to:
      #{yellow targetPath}
  """
  log.moat 1

  fs.mkdir path.dirname linkPath
  fs.link linkPath, targetPath
  return

createLocalLink = (moduleName, argv) ->

  linkPath = path.resolve "node_modules", moduleName
  if argv.f or !fs.exists linkPath
    fs.remove linkPath, true if argv.f

    if targetPath = searchGlobalPaths moduleName
      createLink linkPath, targetPath, argv
      return

    log.warn "Global dependency does not exist: #{green moduleName}"
    return

  log.warn "Link path already exists: #{green linkPath}"
  return

addGlobalPackage = (dir, argv) ->
  if !pack = readPackageJson dir
    log.warn "Cannot find package.json"
    return

  # Link to `npm root -g`
  do ->
    linkPath = path.join npmRoot, pack.name

    if argv.f or !fs.exists linkPath
      removePath linkPath if argv.f
      createLink linkPath, dir, argv
      return

    log.warn "Link path already exists: #{green linkPath}"
    return

  # Link to `npm bin -g`
  if bin = pack.bin then do ->

    if typeof bin == "string"
      bin = {
        [pack.name]: bin
      }

    for scriptName, scriptPath of bin
      scriptPath = path.resolve dir, scriptPath
      binPath = path.join npmBin, scriptName
      log.moat 1
      log.white """
        Creating symlink..
          #{green binPath}
        ..that points to:
          #{yellow scriptPath}
      """
      log.moat 1
      fs.link binPath, scriptPath
      fs.chmod binPath, "755"
    return

createLocalLinks = (dir, argv) ->
  if !pack = readPackageJson dir
    log.warn "Cannot find package.json"
    return

  deps = pack.dependencies
  devDeps = pack.devDependencies if !argv.prod
  peerDeps = pack.peerDependencies if argv.P

  # Packages without dependencies are no-ops.
  return if !deps and !devDeps and !peerDeps
  deps = {...deps, ...devDeps, ...peerDeps}

  for name, version of deps
    linkPath = path.join dir, "node_modules", name
    continue if fs.exists linkPath

    if version.startsWith "file:"
      globalPath = path.resolve dir, version.slice 5
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
          fs.remove linkPath
          log.moat 1
          log.white "Removing broken symlink: #{red name}"
          log.moat 1

    createLink linkPath, globalPath, argv
  return
