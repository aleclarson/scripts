
require "LazyVar"

AsyncTaskGroup = require "AsyncTaskGroup"
Promise = require "Promise"
hasKeys = require "hasKeys"
path = require "path"
exec = require "exec"
git = require "git-utils"
log = require "log"
fs = require "io/sync"

updateTag = require "./tag"

module.exports = (args) ->
  modulePath = path.resolve args._[0] or ""
  moduleName = path.basename modulePath
  process.chdir modulePath.slice 0, modulePath.length - moduleName.length
  promise = updateTag _: [moduleName]
  promise?.then -> updateDistBranch modulePath

#
# Internal helpers
#

ensureMasterBranch = (modulePath, options = {}) ->

  git.isClean modulePath
  .then (isClean) ->

    if isClean
      promise = Promise.resolve()

    else if options.forceClean
      promise = git.resetBranch modulePath, "HEAD", {clean: yes}

    else throw Error "is not clean"

  .then ->
    git.getBranch modulePath
    .then (branch) ->
      if branch isnt "master"
        git.setBranch modulePath, "master"

createDistBranch = (modulePath) ->
  branch = "dist"

  # Delete pre-existing 'dist' branch.
  git.hasBranch modulePath, branch
  .then (hasBranch) ->
    if hasBranch
      git.deleteBranch modulePath, branch

  # Create the 'dist' branch.
  .then ->
    git.addBranch modulePath, branch

ignoredPaths = ["src/", "spec/", "**/*.map", "README.md", "LICENSE"]
updateGitignore = (modulePath) ->
  filePath =  modulePath + "/.gitignore"
  ignored = fs.read(filePath).split "\n"

  if -1 isnt index = ignored.indexOf "js/"
    ignored.splice index, 1

  ignoredPaths.forEach (ignoredPath) ->
    if -1 is ignored.indexOf ignoredPath
      ignored.push ignoredPath

  fs.write filePath, ignored.join "\n"

updatePackageJson = (jsonPath) ->
  pjson = require jsonPath

  delete pjson.plugins
  delete pjson.devDependencies
  delete pjson.implicitDependencies

  # Delete postinstall scripts.
  if pjson.scripts

    delete pjson.scripts.postinstall

    if buildScript = pjson.scripts.build

      # Rebuild *.coffee files (without source maps).
      if buildScript.startsWith "coffee-build "
        exec.sync "coffee -cb -o js src", {cwd: path.dirname jsonPath}

      delete pjson.scripts.build

    unless hasKeys pjson.scripts
      delete pjson.scripts

  pjson = JSON.stringify pjson, null, 2
  fs.write jsonPath, pjson + "\n"

squashDistBranch = (modulePath) ->
  git.getBranch modulePath
  .then (branch) ->
    if branch isnt "dist"
      throw Error "must be on 'dist' branch"
    git.findVersion modulePath, "*"
    .then (version) ->
      if version is null
        throw Error "has no version tag"
      git.resetBranch modulePath, null
      .then -> git.stageFiles modulePath, "*"
      .then -> exec.async "git rm -r --cached .", {cwd: modulePath}
      .then -> git.stageFiles modulePath, "*"
      .then ->
        log.moat 1
        log.white "Publishing:"
        log.moat 0
        log.plusIndent 2
        log.gray "module:  "
        log.green path.basename modulePath
        log.moat 0
        log.gray "version: "
        log.green version
        log.popIndent()
        log.moat 1
        git.pushVersion modulePath, version, {force: yes}

updateDistBranch = (modulePath) ->
  moduleName = path.basename modulePath

  unless fs.isDir modulePath
    throw Error "'#{moduleName}' is not a directory!"

  jsonPath = path.join modulePath, "package.json"
  unless fs.isFile jsonPath
    throw Error "'#{moduleName}' has no package.json file!"

  Promise.all [
    git.isClean modulePath
    git.getBranch modulePath
  ]
  .then (isClean, branch) ->
    return if isClean or (branch is null)
    throw Error "is not clean"

  .then ->
    ensureMasterBranch modulePath
    .then -> createDistBranch modulePath
    .then -> updateGitignore modulePath
    .then -> updatePackageJson jsonPath
    .then -> squashDistBranch modulePath
    .then -> ensureMasterBranch modulePath, {forceClean: yes}

  # End on the 'unstable' branch.
  .then ->
    git.setBranch modulePath, "unstable"

  .fail (error) ->
    log.moat 1
    log.white path.basename modulePath
    log.red " #{error.message}!"
    log.moat 0
    log.gray error.stack
    log.moat 1

  # Ensure the 'js' directory is pristine (git may have deleted it).
  .then ->
    exec.async "coffee -cb -o js src", {cwd: modulePath}
