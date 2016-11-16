
semver = require "semver"
exec = require "exec"
path = require "path"
fs = require "io/sync"

module.exports = (args) ->

  modulePath = process.cwd()
  jsonPath = path.resolve "package.json"
  unless fs.exists jsonPath
    return log.warn "Missing package.json"

  json = require jsonPath
  unless deps = json.dependencies
    return log.warn "No dependencies exist"

  # TODO: Support remote deps?
  for dep, version of deps
    [repo, version] = version.split "#"
    continue unless verifyVersion version
    latestVersion = fetchLatestVersion dep
    continue unless verifyVersion latestVersion
    continue unless semver.gt latestVersion, version
    log.moat 1
    log.white dep
    log.gray " current: "
    log.red version
    log.gray " latest: "
    log.yellow latestVersion
    log.moat 1

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
