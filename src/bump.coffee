
semver = require "semver"
path = require "path"
git = require "git-utils"
fs = require "fsx"

bumpDependencies = require "./utils/bumpDependencies"

module.exports = (args) ->

  if args._.length
    bumpDependencies args._,
      all: Boolean args.A or args.all
      dev: Boolean args.D or args.dev
      force: Boolean args.f
      releaseType: (args.p and "patch") or (args.m and "minor") or (args.M and "major")

  else bumpCurrentPackage args

bumpCurrentPackage = (args) ->
  modulePath = process.cwd()
  jsonPath = path.resolve "package.json"
  json = require jsonPath

  version = args.v or
    semver.inc json.version,
      if args.minor then "minor"
      else if args.major then "major"
      else "patch"

  log.moat 1
  log.gray json.version
  log.white " -> "
  log.green version
  log.moat 1

  git.isClean modulePath
  .then (wasClean) ->

    readmePath = path.join modulePath, "README.md"
    readme = fs.readFile readmePath
    fs.writeFile readmePath, readme.replace "v#{json.version}", "v#{version}"

    json.version = version
    json = JSON.stringify json, null, 2
    fs.writeFile jsonPath, json + log.ln

    return unless wasClean
    git.stageFiles modulePath, "*"
    .then -> git.commit modulePath, "Bump to v#{version}"
    .then -> git.pushBranch modulePath, {force: true}
