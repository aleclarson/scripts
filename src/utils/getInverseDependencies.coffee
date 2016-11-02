
PureObject = require "PureObject"
assertType = require "assertType"
isType = require "isType"

module.exports = (mods) ->
  assertType mods, Object.or PureObject
  inverse = Object.create null
  for name, {json} of mods
    inverse[name] ?= []
    continue unless isType json.dependencies, Object
    Object.keys(json.dependencies).forEach (dep) ->
      if inverse[dep]
      then inverse[dep].push name
      else inverse[dep] = [name]
  return inverse
