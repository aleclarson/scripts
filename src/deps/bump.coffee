
sortObject = require "sortObject"
semver = require "semver"
path = require "path"
exec = require "exec"
git = require "git-utils"
fs = require "io/sync"

npmRoot = exec.sync "npm root -g"

module.exports = (args) ->

  modulePath = process.cwd()
  jsonPath = path.join modulePath, "package.json"
  if not fs.isFile jsonPath
    log.warn "Current directory is not a valid module: '#{modulePath}'"
    return

  json = JSON.parse fs.read jsonPath

  if not args._.length
    log.warn "Must specify at least one dependency name!"
    return

  for depName in args._
    bumpDep depName, args, {path: modulePath, json}

  json = JSON.stringify json, null, 2
  fs.write jsonPath, json + log.ln
  return

bumpDep = (depName, args, parent) ->

  deps = parent.json.dependencies or {}
  oldVersion = deps[depName]

  if not isRemote = args.remote is yes
    if args.ours is yes
      userName = exec.sync "git config --get user.name"
    else if oldVersion and oldVersion.indexOf("/") >= 0
      userName = oldVersion.split("/")[0]

  newVersion = args.v or
    getLatestVersion depName, isRemote

  if not newVersion
    log.warn """
      No local version found for '#{depName}'!

      Specify -r to use latest NPM version.
      Specify -v to use custom version.
    """
    return

  unless semver.valid(newVersion) or semver.validRange(newVersion)
    log.warn "Malformed version: '#{newVersion}'"
    return

  versionPath = newVersion
  if userName
    versionPath = userName + "/" + depName + "#" + newVersion

  if versionPath is oldVersion
    log.warn "Dependency is up-to-date!"
    return

  deps[depName] = versionPath
  parent.json.dependencies = sortObject deps

  log.moat 1
  log.white depName
  log.moat 0
  if oldVersion
    if userName
    then log.gray oldVersion.split("#")[1]
    else log.gray oldVersion
    log.white " -> "
  log.green newVersion
  log.moat 1

  depPath = path.resolve parent.path, "node_modules", depName
  return if fs.exists depPath

  {green, yellow} = log.color

  if args.ours is yes
    targetPath = path.resolve npmRoot, depName
    log.moat 1
    log.white """
      Creating symlink..
        #{green depPath}
      ..that points to:
        #{yellow targetPath}
    """
    log.moat 1
    log.flush()

    fs.writeDir path.dirname depPath
    fs.writeLink depPath, targetPath
    return

  log.moat 1
  log.white """
    Installing:
      #{green depPath}
  """
  log.moat 1
  log.flush()

  try exec.sync "npm install #{depPath}", cwd: parent.path
  catch error
     throw error unless /WARN/.test error.message
  return

getLatestVersion = (moduleName, remote) ->

  if remote
    return exec.sync "npm view #{moduleName} version"

  moduleParent = process.cwd()
  while moduleParent isnt path.sep
    modulePath = path.join moduleParent, "node_modules", moduleName
    break if fs.isDir modulePath
    moduleParent = path.dirname moduleParent

  modulePath ?= path.join npmRoot, moduleName
  jsonPath = path.join modulePath, "package.json"
  return if not fs.isFile jsonPath

  json = JSON.parse fs.read jsonPath
  return json.version
