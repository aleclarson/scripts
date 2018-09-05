
emptyFunction = require "emptyFunction"
assertValid = require "assertValid"
path = require "path"
fs = require "fsx"

readModules = (root, filter = emptyFunction.thatReturnsTrue) ->
  assertValid root, "string"
  assertValid filter, "function"

  mods = Object.create null
  fs.readDir(root).forEach (file) ->
    file = path.resolve root, file

    jsonPath = path.join file, "package.json"
    if fs.exists jsonPath
      json = require jsonPath

      if !json.name
        return console.warn "Missing module name: '#{file}'"

      if collision = mods[json.name]
        throw Error "Duplicate module name: '#{json.name}'\n\n#{file}\n#{collision.file}"

      if filter file, json
        mods[json.name] = {file, json}
        return

  return mods

module.exports = readModules
