
AsyncTaskGroup = require "AsyncTaskGroup"
emptyFunction = require "emptyFunction"
SortedArray = require "sorted-array"
assertType = require "assertType"
path = require "path"
fs = require "io/sync"

module.exports = (files, filter = emptyFunction.thatReturnsTrue) ->
  assertType files, Array
  assertType filter, Function

  sorted = SortedArray [], (a, b) ->
    if a.deps and a.deps[b.name]
    then 1 else -1

  tasks = AsyncTaskGroup {maxConcurrent: 10}
  tasks.map files, (file) ->
    Promise.try -> filter file
    .then (isValid) ->
      return if not isValid
      jsonPath = path.resolve file, "package.json"
      return if not fs.exists jsonPath
      json = require jsonPath
      sorted.insert
        name: json.name
        deps: json.dependencies or {}

  .then -> sorted.array
