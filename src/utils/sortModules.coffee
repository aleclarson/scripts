assertValid = require "assertValid"

sortModules = (mods, sort) ->
  assertValid mods, "object"
  assertValid sort, "function"

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
