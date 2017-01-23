
semver = require "semver"
path = require "path"
git = require "git-utils"
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

  git.isClean modulePath
  .then (wasClean) ->

    readmePath = path.join modulePath, "README.md"
    readme = fs.read readmePath
    fs.write readmePath, readme.replace "v#{json.version}", "v#{version}"

    json.version = version
    json = JSON.stringify json, null, 2
    fs.write jsonPath, json + log.ln

    return unless wasClean
    git.stageFiles modulePath, "*"
    .then -> git.commit modulePath, "Bump to v#{version}"
    .then -> git.pushBranch modulePath
