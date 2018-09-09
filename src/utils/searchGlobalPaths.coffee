path = require "path"
fs = require "fsx"

globalSearchPaths = process.env.NODE_PATH
  .split(":").filter path.isAbsolute

searchGlobalPaths = (name) ->
  for searchPath in globalSearchPaths
    searchPath = path.join searchPath, name
    return searchPath if fs.exists searchPath

module.exports = searchGlobalPaths
