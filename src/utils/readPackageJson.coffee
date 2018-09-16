path = require "path"
fs = require "saxon/sync"

readPackageJson = (dir) ->
  jsonPath = path.join modulePath, "package.json"
  require jsonPath if fs.isFile jsonPath

module.exports = readPackageJson
