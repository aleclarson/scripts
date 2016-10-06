
sortObject = require "sortObject"
semver = require "semver"
path = require "path"
exec = require "exec"
git = require "git-utils"
fs = require "io/sync"

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

  promise =
    if args.commit is no
    then Promise yes
    else git.isClean modulePath

  promise.then (isClean) ->

    if not isClean
      log.warn "Repository has uncommitted changes!"
      return

    for depName in args._
      bumpDep depName, args, json

    json = JSON.stringify json, null, 2
    fs.write jsonPath, json + log.ln

    return if args.commit is no
    git.stageFiles modulePath, "*"
    .then ->
      git.commit modulePath, args.m or
        if oldVersion then "Upgrade '#{depName}' to v#{newVersion}"
        else "Depend on '#{depName}'"

bumpDep = (depName, args, json) ->

  deps = json.dependencies or {}
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
  json.dependencies = sortObject deps

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

getLatestVersion = (moduleName, remote) ->

  if remote
    return exec.sync "npm view #{moduleName} version"

  moduleParent = process.cwd()
  while moduleParent isnt "."
    modulePath = path.join moduleParent, "node_modules", moduleName
    break if fs.isDir modulePath
    moduleParent = path.dirname moduleParent

  if not modulePath
    npmRoot = exec.sync "npm root -g"
    modulePath = path.join npmRoot, moduleName

  jsonPath = path.join modulePath, "package.json"
  return if not fs.isFile jsonPath
  json = JSON.parse fs.read jsonPath
  return json.version
