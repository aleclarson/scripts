
# deps scan
#   Prints any package that has multiple versions being used by the recursive set of dependencies

assertValidVersion = require "assertValidVersion"
emptyFunction = require "emptyFunction"
parseBool = require "parse-bool"
syncFs = require "io/sync"
prompt = require "prompt"
assert = require "assert"
sync = require "sync"
Path = require "path"
log = require "log"
has = require "has"

module.exports = (options) ->

  if moduleName = options._.shift()
    return lotus.Module.load moduleName
    .then parseDependencies

  lotus.Module.crawl lotus.path
  .then (mods) ->
    Promise.chain mods, parseDependencies

parseDependencies = (mod) ->

  return if lotus.isModuleIgnored mod.name

  mod.parseDependencies
    ignore: "**/{node_modules,__tests__}/**"

  .then -> printDependencies mod

printDependencies = (mod) ->

  return unless mod.files
  return unless Object.keys(mod.files).length

  # The map of explicit dependencies in 'package.json'
  explicitDeps = mod.config.dependencies ?= {}

  # The list of implicit dependencies in 'package.json'
  implicitDeps = createImplicitMap mod

  # Absolute dependencies that were imported, but are not listed in 'package.json'
  unexpectedDeps = Object.create null

  # Relative dependencies that were imported, but do not exist
  missingDeps = Object.create null

  # Absolute dependencies that were imported and are already listed in 'package.json'
  foundDeps = Object.create null

  sync.each mod.files, (file) ->

    sync.each file.dependencies, (dep) ->

      if dep.startsWith "image!"
        return

      if dep[0] is "."
        depPath = lotus.resolve dep, file.path
        return if depPath
        files = missingDeps[dep] ?= []
        files.push file
        return

      parts = dep.split "/"
      dep = parts[0] if parts.length

      if explicitDeps[dep] or implicitDeps[dep]
        files = foundDeps[dep] ?= []
        files.push file
        return

      files = unexpectedDeps[dep] ?= []
      files.push file

  # Absolute dependencies that are never imported.
  unusedDeps = Object.create null
  sync.each explicitDeps, (_, dep) ->
    return if foundDeps[dep]
    unusedDeps[dep] = yes

  unexpectedDepNames = Object.keys unexpectedDeps
  missingDepPaths = Object.keys missingDeps
  unusedDepNames = Object.keys unusedDeps

  # Skip modules that have no problems.
  return unless unexpectedDepNames.length or missingDepPaths.length or unusedDepNames.length

  log.moat 1
  log.bold mod.name
  log.plusIndent 2

  Promise.try ->
    printUnexpectedAbsolutes mod, unexpectedDepNames, unexpectedDeps

  .then ->
    printUnusedAbsolutes mod, unusedDepNames, implicitDeps
    printMissingRelatives mod, missingDepPaths, missingDeps
    log.popIndent()
    log.moat 1

printUnusedAbsolutes = (mod, depNames, implicitDeps) ->

  return unless depNames.length

  printResults "Unused absolutes: ", depNames

  { dependencies } = mod.config
  return Promise.chain depNames, (depName) ->

    log.moat 1
    log.gray "Should "
    log.yellow depName
    log.gray " be removed?"

    shouldRemove = prompt.sync()
    if shouldRemove is "s"
      throw Error "skip dependency"

    shouldRemove = parseBool shouldRemove
    return if not shouldRemove

    if has dependencies, depName
      delete dependencies[depName]

    else
      delete implicitDeps[depName]

  .fail (error) ->
    return if error.message is "skip dependency"
    log.moat 1
    log.red error.stack
    log.moat 1
    throw error

  .then ->
    log.moat 1
    log.green "Done!"
    log.moat 1
    mod.saveConfig()

printMissingRelatives = (mod, depNames, dependers) ->

  return unless depNames.length

  printResults "Missing relatives: ", depNames, (depName) ->
    log.plusIndent 2
    sync.each dependers[depName], (file) ->
      log.moat 0
      log.gray.dim Path.relative file.module.path, file.path
    log.popIndent()

printUnexpectedAbsolutes = (mod, depNames, dependers) ->

  return unless depNames.length

  printResults "Unexpected absolutes: ", depNames, (depName) ->
    log.plusIndent 2
    sync.each dependers[depName], (file) ->
      log.moat 0
      log.gray.dim Path.relative file.module.path, file.path
    log.popIndent()

  return Promise.chain depNames, (depName) ->

    log.moat 1
    log.gray "Which version of "
    log.yellow depName
    log.gray " should be depended on?"

    version = prompt.sync()
    return if not version?

    if version is "s"
      throw Error "skip dependency"

    if version is "."
      implicitDeps = mod.config.implicitDependencies ?= []
      implicitDeps.push depName
      implicitDeps.sort (a, b) -> a > b # sorted by ascending
      mod.saveConfig()
      return

    if 0 <= version.indexOf ":"
      [username, version] = version.split ":"
      username = lotus.config.github?.username if not username.length
      assert username.length, "Must provide a username for git dependencies!"
      version = username + "/" + depName + "#" + version

    assertValidVersion depName, version

    .then ->
      mod.config.dependencies ?= {}
      mod.config.dependencies[depName] = version
      mod.saveConfig()

    .fail (error) ->
      log.moat 1
      log.gray.dim "{ depName: "
      log.white depName
      log.gray.dim ", version: "
      log.white version
      log.gray.dim " }"
      log.moat 0
      log.red error.stack
      log.moat 1

  .fail (error) ->
    return if error.message is "skip dependency"
    throw error

printResults = (title, deps, iterator = emptyFunction) ->

  log.moat 1
  log.yellow title
  log.plusIndent 2

  for dep in deps
    log.moat 1
    log.white dep
    log.moat 0
    iterator dep
    log.moat 1

  log.popIndent()
  log.moat 1

createImplicitMap = (mod) ->
  map = Object.create null
  deps = mod.config.implicitDependencies
  if Array.isArray deps
    map[dep] = yes for dep in deps
  return map
