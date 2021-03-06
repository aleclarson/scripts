
sortObject = require "sortObject"
semver = require "semver"
path = require "path"
git = require "git-utils"
log = require "log"
fs = require "fsx"

searchGlobalPaths = require "./searchGlobalPaths"

module.exports = (input, opts) ->

  unless input.length
    return log.warn "Must provide at least one dependency!"

  deps = input.map parseDependency
  prop = if opts.dev then "devDependencies" else "dependencies"

  for cwd from yieldPackages(opts)
    packPath = cwd + "/package.json"
    pack = readJson packPath

    # `opts.all` only cares about upgrading
    continue if opts.all and !pack[prop]
    pack[prop] or= {}

    addCount = 0
    upgradeCount = 0

    deps.forEach (dep) ->

      # Handle local dependencies.
      if dep.site == "file"

        if opts.all
          log.warn "Local packages are not supported in all mode"
          return

        if dep.name[0] == "/"
          log.warn "Local package cannot be an absolute path: '#{dep.name}'"
          return

        # Ensure the package exists and initialize some properties.
        if !loadLocalPackage dep
          log.warn "Local package does not exist: '#{dep.name}'"
          return

        # Mark the dependency as resolved.
        newValue = "file:" + dep.name
        localPath = "../" + dep.name

      # The name used to import this dependency
      name = dep.alias or dep.name

      # Parse metadata from the previous value.
      if oldValue = pack[prop][name]
        oldProps = parseVersion oldValue

      # `opts.all` only cares about upgrading
      else if opts.all
        return

      # The symlink in node_modules
      linkPath = cwd + "/node_modules/" + name

      # Use the exact old version.
      if oldProps and fs.exists linkPath + "/package.json"
        oldProps.version = JSON.parse(fs.readFile linkPath + "/package.json").version

      # Git deps are used as-is
      if dep.scope and dep.site != "npm"
        newValue = dep.scope + "/" + dep.name
        newValue += "#" + dep.tag if dep.tag

        # Github is the implicit prefix
        if dep.site != "github"
          newValue += dep.site + ":"

        # Github deps may be globally installed with `pnpm`
        else if dep.tag
          localPath = searchGlobalPaths ".github.com/#{dep.scope}/#{dep.name}/" + dep.tag

      # Use `opts.releaseType` when a previous version exists and no version was given.
      if opts.releaseType and oldProps and !(dep.version or dep.tag)
        # Aliases, git tags, and local deps cannot be bumped.
        if !dep.alias and !oldProps.tag and oldProps.site != "file"
          dep.version = makeSemverRange oldProps.version, opts.releaseType

      # Find the first global package with the desired name.
      if !newValue and (localPath = searchGlobalPaths dep.name + "/package.json")

        # Sanity check on global package.json
        if !newVersion = readJson(localPath).version
          log.warn "Global package has no version: '#{localPath}'"
          return

        # The global package must satisfy the desired version.
        localPath =
          if !dep.version or semver.satisfies newVersion, dep.version
          then path.dirname localPath
          else null

      # The `pnpm-global` folder may have the desired version.
      if !localPath and dep.version
        {path: localPath, version: newVersion} = pnpmSearch dep

      # The dependency must exist locally to be linked.
      if !localPath and !opts.force

        if !newValue
          newValue = dep.name
          newValue += "@" + dep.version if dep.version

        log.warn "Global package matching '#{newValue}' not found"
        return

      # Ensure a dependency value exists for npm packages.
      if !newValue

        newVersion or= dep.version or "*"
        if semver.valid newVersion
          newVersion = "^" + newVersion

        newValue =
          if dep.alias
          then dep.site + ":" + dep.name + "@" + newVersion
          else newVersion

      # Remove the previous symlink.
      if fs.isLink linkPath
        fs.removeFile linkPath

      # The user must manually delete real directories and files.
      else if fs.exists linkPath
        log.warn "Cannot overwrite non-link dependency: '#{linkPath}'"
        return

      # The symlink cannot be created when no global package was found.
      # Usually, we catch this further up, but not when `opts.force` is used.
      if localPath
        fs.writeDir path.dirname linkPath
        fs.writeLink linkPath, localPath

      # Apply the change if necessary.
      if newValue != oldValue
        pack[prop][name] = newValue
        if oldValue then upgradeCount++ else addCount++

        log.moat 1
        log.white dep.name
        if dep.alias
          log.gray " as "
          log.white dep.alias
        log.moat 0
        log.plusIndent 2
        if oldValue
          log.gray oldProps.version or oldValue
          log.white " -> "
        log.green newVersion or newValue
        log.popIndent()
        log.moat 1

    # Sort the dependencies if some were added.
    if addCount
      pack[prop] = sortObject pack[prop]

    # Save the package.json if changes were made.
    if addCount or upgradeCount
      writeJson packPath, pack
      return

#
# Helpers
#

loadLocalPackage = (dep) ->
  packPath = dep.name + "/package.json"
  return false if !fs.isFile packPath
  pack = JSON.parse fs.readFile(packPath)
  dep.alias or= pack.name
  dep.version = pack.version or "0.0.0"
  return true

pnpmSearch = (dep) ->
  versionDir = searchGlobalPaths ".registry.npmjs.org/" + dep.name
  if versionDir and (version = semver.maxSatisfying fs.readDir(versionDir), dep.version)
    {path: path.join(versionDir, version, "node_modules", dep.name), version}
  else {path: null, version: null}

makeSemverRange = (version, releaseType) ->
  {major, minor, patch} = semver.coerce version
  switch releaseType
    when "patch" then "~#{major}.#{minor}.#{patch + 1}"
    when "minor" then "^#{major}.#{minor + 1}"
    when "major" then String major + 1

# When `opts.all` is true, all packages in the working directory are yielded.
# Otherwise, the working directory is returned.
yieldPackages = (opts) ->
  cwd = process.cwd()

  if opts.all
    for dir in fs.readDir cwd
      dir = cwd + "/" + dir
      yield dir if fs.isFile dir + "/package.json"
    return

  if !fs.isFile cwd + "/package.json"
    log.warn "Current directory is not a package!"
    return

  yield cwd

# Parse metadata from a dependency string
parseDependency = (input) ->

  # Default values
  name = input
  scope = null
  site = null
  alias = null
  version = null
  tag = null

  # Handle local dependencies.
  if name.startsWith "file:"
    site = "file"
    name = name.slice 5
    return {name, scope, site, alias, version, tag}

  # Check for a version
  atIdx = name.indexOf "@", 1
  if atIdx != -1
    version = name.slice atIdx + 1
    name = name.slice 0, atIdx

    # An alias may follow the '@'
    if !semver.valid(version) and !semver.validRange(version)
      alias = name
      name = version
      version = null

      # Check for 'npm:' or similar
      siteIdx = name.indexOf ":", 1
      if siteIdx != -1
        site = name.slice 0, siteIdx
        name = name.slice siteIdx + 1

        # Handle local dependencies.
        if site == "file"
          return {name, scope, site, alias, version, tag}

      # Check for a version (again)
      atIdx = name.indexOf "@", 1
      if atIdx != -1
        version = name.slice atIdx + 1
        name = name.slice 0, atIdx

    if version == ""
      log.warn """
        Invalid dependency: '#{input}'
        Version cannot be empty
      """
      return null

  # Scoped
  slashIdx = name.indexOf "/"
  if slashIdx != -1
    scope = name.slice 0, slashIdx

    # Git dependency
    if scope[0] != "@"
      name = name.slice slashIdx + 1
      site or= "github"

      if version
        log.warn """
          Invalid dependency: '#{input}'
          Must use '#' instead of '@' to specify Github tag
        """
        return null

      tagIdx = name.indexOf "#", 1
      if tagIdx != -1
        tag = name.slice tagIdx + 1
        name = name.slice 0, tagIdx

        # Check for Git tags that follow semver.
        version = tag if semver.valid tag

  # Ignore pointless aliases.
  if name == alias
    alias = null

  # The default site is npm.
  site or= "npm"

  {name, scope, site, alias, version, tag}

# Parse metadata from a version string
parseVersion = (input) ->

  # Valid versions are simple.
  if semver.valid(input) or semver.validRange(input)
    return {name: null, scope: null, alias: null, version: input, tag: null}

  # Default values
  name = input
  scope = null
  site = null
  version = null

  # Check for "npm:" or similar
  siteIdx = name.indexOf ":", 1
  if siteIdx != -1
    site = name.slice 0, siteIdx
    name = name.slice siteIdx + 1

    # Handle local dependencies.
    if site == "file"
      return {name, scope, site, alias: null, version, tag: null}

  slashIdx = name.indexOf "/", 1
  if slashIdx != -1
    scope = name.slice 0, slashIdx

    # Git dependency
    if scope[0] != "@"
      name = name.slice slashIdx + 1
      site or= "github"

      tagIdx = name.indexOf "#"
      if tagIdx != -1
        tag = name.slice tagIdx + 1
        name = name.slice 0, tagIdx

        # Check for Git tags that follow semver.
        version = tag if semver.valid tag

      return {name, scope, site, alias: null, version, tag}

  # Look for version.
  if siteIdx != -1
    atIdx = name.indexOf "@", 2
    if atIdx != -1
      version = name.slice atIdx + 1
      name = name.slice 0, atIdx

  # The default site is npm.
  else site or= "npm"

  return {name, scope, site, alias: null, version, tag: null}

readJson = (path) ->
  JSON.parse fs.readFile path

writeJson = (path, json) ->
  fs.writeFile path, JSON.stringify(json, null, 2) + log.ln
