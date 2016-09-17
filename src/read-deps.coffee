
{resolveModule} = require "resolve"

exec = require "exec"
path = require "path"
sync = require "sync"
fs = require "io/sync"

module.exports = (args) ->

  entryPath =
    if args._.length
    then path.resolve args._[0]
    else process.cwd()

  deps = readDeps entryPath,
    depth: args.depth or Infinity

  log.moat 1
  log.white "Found #{Object.keys(deps).length} dependencies!"
  log.moat 1

  # Convert sets to arrays (for JSON.stringify)
  sync.each deps, (moduleJson, moduleName) ->
    moduleJson.versions = Array.from moduleJson.versions
    moduleJson.dependers = Array.from moduleJson.dependers
    return

  manifest = JSON.stringify deps, null, 2
  fs.write entryPath + "/manifest.json", manifest
  return

#
# Helpers
#

npmRoot = exec.sync "npm root -g"

# Protect against miscapitalized module names.
lowercased = Object.create null

readDeps = (modulePath, options = {}) ->
  options.deps ?= Object.create null

  if not path.isAbsolute modulePath
    throw Error "'modulePath' must be absolute:\n  #{modulePath}"

  moduleName = path.basename modulePath
  moduleHash = moduleName.toLowerCase()
  if collision = lowercased[moduleHash]

    if moduleName isnt collision.dep
      log.warn """
        Possibly incorrect capitalization:
          {from: #{options.parent}, to: #{moduleName}}

        This module is also required with a similar name:
          #{collision.parent} -> #{collision.dep}
      """
      return

    lowercased[moduleHash] =
      parent: options.parent
      dep: moduleName

  jsonPath = path.join modulePath, "package.json"
  if not fs.isFile jsonPath
    log.warn "Package does not exist:\n  #{jsonPath}"
    return options.deps

  # Link the module into the global node_modules.
  if 0 > modulePath.indexOf "/node_modules/"
    globalPath = path.join npmRoot, moduleName
    linkDep globalPath, modulePath

  json = require jsonPath
  unless json and json.dependencies
    return options.deps

  options._depth ?= 0
  depth = options._depth += 1

  sync.each json.dependencies, (version, depName) ->
    {red, gray} = log.color

    # Check for git dependencies.
    if version.indexOf(path.sep) >= 0
      depPath = resolveModule depName, modulePath
      if not depPath
        log.warn """
          Failed to resolve dependency:
            #{modulePath}
            -> #{red depName}
        """
        return

      if dep = options.deps[depPath]
        dep.versions.add version
        dep.dependers.add moduleName
        return

      log.it gray depPath
      options.deps[depPath] =
        versions: new Set [version]
        dependers: new Set [moduleName]

      if depth < options.depth
        options.parent = modulePath
        readDeps depPath, options
        options._depth = depth
      return

    if dep = options.deps[depName]
      dep.versions.add version
      dep.dependers.add moduleName
      return

    log.it gray depName
    options.deps[depName] =
      versions: new Set [version]
      dependers: new Set [moduleName]
    return

  options._depth -= 1
  return options.deps

linkDep = (linkPath, modulePath) ->
  return if fs.isLink(linkPath) and not fs.isLinkBroken(linkPath)
  {green} = log.color
  log.moat 1
  log """
    Linking:
      #{green linkPath}
      -> #{modulePath}
  """
  log.moat 1
  fs.writeLink linkPath, modulePath
