
PureObject = require "PureObject"
assertType = require "assertType"

sortModules = (mods, sort) ->
  assertType mods, PureObject

  sorted = []
  names = Object.keys mods
  count = names.length
  while count > 0
    index = 0
    while index < count
      mod = mods[names[index]]
      if sort mod
        count -= 1
        names.splice index, 1
        sorted.push mod
      else
        index += 1

  return sorted

module.exports = sortModules
