path = require "path"
fs = require "saxon/sync"

readPackageJson = (dir) ->
  pack = path.join dir, "package.json"
  require pack if fs.isFile pack

module.exports = readPackageJson
