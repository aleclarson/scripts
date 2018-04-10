
sortObject = require "sortObject"
semver = require "semver"
prompt = require "prompt"
path = require "path"
exec = require "exec"
git = require "git-utils"
fs = require "io/sync"

npmRoot = exec.sync "npm root -g"

module.exports = (depNames, args) ->

  unless depNames.length
    return log.warn "Must specify at least one dependency name!"

  if args.v?

    if depNames.length > 1
      return log.warn "Cannot specify -v when updating multiple dependencies!"

    unless semver.valid(args.v) or semver.validRange(args.v)
      return log.warn "Malformed version: '#{args.v}'"

  if args.scan
  then updateDependingPackages depNames, args
  else updateCurrentPackage depNames, args

updateCurrentPackage = (depNames, args) ->

  jsonPath = path.resolve "package.json"
  unless fs.isFile jsonPath
    log.warn "Missing json: '#{jsonPath}'"
    return

  latestVersions = readVersions depNames, args
  updatePackageJson jsonPath, (json) ->
    parent = {json, path: path.dirname jsonPath}
    for depName, latestVersion of latestVersions
      if latestVersion
      then bumpDependency depName, latestVersion, args, parent
      else log.warn "Missing version: '#{depName}'"
    return

updateDependingPackages = (depNames, args) ->
  latestVersions = readVersions depNames, args
  moduleNames = fs.readDir "."
  for moduleName in moduleNames
    cancelled =
      updateDependingPackage moduleName, latestVersions, args
    return if cancelled
  return

missingVersions = {}

updateDependingPackage = (moduleName, latestVersions, args) ->
  modulePath = path.resolve moduleName
  jsonPath = path.join modulePath, "package.json"
  return false unless fs.isFile jsonPath

  updatePackageJson jsonPath, (json) ->
    deps = json.dependencies
    devDeps = json.devDependencies
    return false unless deps or devDeps

    parent = {json, path: modulePath}
    for depName, latestVersion of latestVersions

      if deps?
        oldValue = deps[depName]

      if devDeps? and not oldValue
        oldValue = devDeps[depName]

      continue unless oldValue

      unless latestVersion
        unless missingVersions[depName]
          missingVersions[depName] = true
          log.warn "Missing version: '#{depName}'"
        continue

      oldVersion = parseVersion oldValue
      continue if semver.gte oldVersion, latestVersion

      diff = semver.diff oldVersion, latestVersion
      continue if args.only? and diff isnt args.only

      log.moat 1
      log.yellow moduleName
      log.moat 0
      log.plusIndent 2
      log.gray "current: "
      log.white oldVersion
      log.moat 0

      # Auto-bump patch versions.
      if diff is "patch"
        log.gray "auto-bumping: "
        log.green latestVersion
        log.moat 1
        shouldBump = true

      else
        log.gray "latest:  "
        log.green latestVersion
        log.moat 1
        shouldBump = prompt.sync {bool: true}

      log.popIndent()

      if shouldBump is null
        return true

      if shouldBump
        bumpDependency depName, latestVersion, args, parent

    return false

#
# Internal helpers
#

getLatestVersion = (moduleName, isRemote) ->

  if isRemote
    return exec.sync "npm view #{moduleName} version"

  moduleParent = process.cwd()
  while moduleParent isnt path.sep
    modulePath = path.join moduleParent, "node_modules", moduleName
    break if fs.isDir modulePath
    moduleParent = path.dirname moduleParent

  modulePath ?= path.join npmRoot, moduleName
  jsonPath = path.join modulePath, "package.json"
  return unless fs.isFile jsonPath

  json = JSON.parse fs.read jsonPath
  return json.version

readVersions = (depNames, args) ->
  versions = {}

  if args.v?
    versions[depNames[0]] = args.v
    return versions

  for depName in depNames
    versions[depName] = getLatestVersion String(depName), args.remote
  return versions

updatePackageJson = (jsonPath, updater) ->
  json = JSON.parse fs.read jsonPath
  result = updater json
  json = JSON.stringify json, null, 2
  fs.write jsonPath, json + log.ln
  return result

parseVersion = (string) ->
  if 0 <= string.indexOf "#"
    return string.split("#")[1]
  return string

parseUsername = (string) ->
  parts = string.split "/"
  if 0 <= string.indexOf "://"
    parts = parts.splice -2
  if parts.length > 1
    return parts.shift()
  return null

bumpDependency = (depName, newVersion, args, parent) ->

  depsKey = if args.dev then "devDependencies" else "dependencies"
  deps = parent.json[depsKey] or {}
  oldValue = deps[depName]

  unless args.remote
    username =
      if args.ours then exec.sync "git config --get user.name"
      else if oldValue then parseUsername oldValue
      else null

  newValue =
    if username
    then username + "/" + depName + "#" + newVersion
    else "^" + newVersion

  if newValue is oldValue
    log.warn "#{depName} v#{newVersion} is already installed!"
    return

  deps[depName] = newValue
  parent.json[depsKey] = sortObject deps

  unless args.scan
    log.moat 1
    log.white depName
    log.moat 0
    if oldValue
      log.gray parseVersion oldValue
      log.white " -> "
    log.green newVersion
    log.moat 1

  depPath = path.resolve parent.path, "node_modules", depName
  return if fs.exists depPath

  {green, yellow} = log.color

  if args.ours
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
