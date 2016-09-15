
semver = require "semver"
path = require "path"
fs = require "io/sync"

module.exports = (args) ->

  moduleName = args._[0]
  modulePath =
    if moduleName
    then path.resolve moduleName
    else process.cwd()

  jsonPath = path.join modulePath, "package.json"
  json = require jsonPath

  version = args.v or
    semver.inc json.version,
      if args.m or args.minor
      then "minor"
      else if args.p or args.patch
      then "patch"
      else "major"

  log.moat 1
  log.gray json.version
  log.white " -> "
  log.green version
  log.moat 1

  readmePath = path.join modulePath, "README.md"
  readme = fs.read readmePath
  fs.write readmePath, readme.replace "v#{json.version}", "v#{version}"

  json.version = version
  json = JSON.stringify json, null, 2
  fs.write jsonPath, json + log.ln
  return
