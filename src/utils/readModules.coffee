
emptyFunction = require "emptyFunction"
assertType = require "assertType"
path = require "path"
fs = require "fsx"

readModules = (root, filter = emptyFunction.thatReturnsTrue) ->
  assertType root, String
  mods = Object.create null
  files = fs.readDir root
  files.forEach (file) ->
    file = path.resolve root, file
    jsonPath = path.join file, "package.json"
    return unless fs.exists jsonPath
    json = require jsonPath
    if not json.name
      return console.warn "Missing module name: '#{file}'"
    if collision = mods[json.name]
      throw Error "Duplicate module name: '#{json.name}'\n\n#{file}\n#{collision.file}"
    if filter file, json
      mods[json.name] = {file, json}
  return mods

module.exports = readModules
