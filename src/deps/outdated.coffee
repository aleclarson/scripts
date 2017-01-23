
semver = require "node-semver"
exec = require "exec"
path = require "path"
fs = require "io/sync"

module.exports = (args) ->

  if args.scan
    files = fs.readDir "."
    for file in files
      modulePath = path.resolve file
      printOutdated modulePath, args
    return

  modulePath = path.resolve args._[0] or process.cwd()
  printOutdated modulePath, args
  return

printOutdated = (modulePath, args) ->

  jsonPath = path.resolve modulePath, "package.json"
  unless fs.exists jsonPath
    args.scan or log.warn "Missing package.json"
    return

  json = require jsonPath
  unless deps = json.dependencies
    args.scan or log.warn "No dependencies exist"
    return

  outdated = []

  # TODO: Support remote deps?
  for dep, version of deps
    [repo, version] = version.split "#"
    continue unless verifyVersion version
    latestVersion = fetchLatestVersion dep
    continue unless verifyVersion latestVersion
    continue unless semver.gt latestVersion, version
    outdated.push {dep, version, latestVersion}

  return unless outdated.length

  if args.scan
    log.moat 1
    log.white path.basename modulePath
    log.plusIndent 2

  for {dep, version, latestVersion} in outdated
    log.moat 1
    log.white dep
    log.gray " current: "
    log.red version
    log.gray " latest: "
    log.yellow latestVersion
    log.moat 1

  if args.scan
    log.popIndent()
  return

#
# Helpers
#

npmRoot = exec.sync "npm root -g"

latestVersions = Object.create null

verifyVersion = (version) ->
  if version
    return yes if semver.valid version
    return yes if semver.validRange version
  return no

fetchLatestVersion = (moduleName) ->
  return version if version = latestVersions[moduleName]
  jsonPath = path.join npmRoot, moduleName, "package.json"
  return null unless fs.exists jsonPath
  json = require jsonPath
  latestVersions[moduleName] = json.version
  return json.version
