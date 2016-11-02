
{resolvePath} = require "resolve"

emptyFunction = require "emptyFunction"
hasKeys = require "hasKeys"
Finder = require "finder"
OneOf = require "OneOf"
glob = require "globby"
path = require "path"
fs = require "io/sync"

config = require "../../config.json"
ignored = OneOf config.ignore

findRequire = Finder
  regex: /(\brequire\s*?\(\s*?)(['"])([^'"]+)(\2\s*?\))/g
  group: 3

module.exports = (args) ->

  if not args._.length
    return log.warn "Must provide a module path!"

  modulePath = path.resolve args._.shift()
  jsonPath = path.join modulePath, "package.json"
  json = require jsonPath
  return if ignored.test json.name

  explicitDeps = json.dependencies ?= {}
  implicitDeps = do ->
    deps = {}
    if Array.isArray json.implicitDependencies
      deps[dep] = yes for dep in json.implicitDependencies
    return deps

  foundDeps = Object.create null
  missingDeps = Object.create null
  unexpectedDeps = Object.create null

  push = (obj, key, value) ->
    if obj[key]
    then obj[key].push value
    else obj[key] = [value]

  files = glob.sync modulePath + "/**/*.js"
  for file in files
    continue if /\/node_modules\//.test file
    js = fs.read file
    deps = findRequire.all js
    for dep in deps
      continue if dep.startsWith "image!"

      if dep[0] is "."
        depPath = resolvePath dep, {parent: path.dirname file}
        depPath or push missingDeps, dep, file
        continue

      depParts = dep.split "/"
      if depParts.length
        dep = depParts[0]

      if explicitDeps[dep] or implicitDeps[dep]
      then push foundDeps, dep, file
      else push unexpectedDeps, dep, file

  unusedDeps = Object.create null
  Object.keys(explicitDeps).forEach (dep) ->
    foundDeps[dep] or unusedDeps[dep] = yes

  printDependers = (dep, dependers) ->
    log.plusIndent 2
    for file in dependers
      log.moat 0
      log.gray.dim path.relative modulePath, file
    log.popIndent()

  printResults "Missing relatives: ", missingDeps, printDependers
  printResults "Unexpected absolutes: ", unexpectedDeps, printDependers
  printResults "Unused absolutes: ", unusedDeps

printResults = (title, deps, iterator = emptyFunction) ->

  return unless hasKeys deps
  log.moat 1
  log.yellow title
  log.plusIndent 2

  for dep, dependers of deps
    log.moat 1
    log.white dep
    log.moat 0
    iterator dep, dependers
    log.moat 1

  log.popIndent()
  log.moat 1
