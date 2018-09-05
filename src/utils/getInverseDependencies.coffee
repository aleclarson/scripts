assertValid = require "assertValid"
isValid = require "isValid"

module.exports = (mods) ->
  assertValid mods, "object"

  inverse = Object.create null
  for name, {json} of mods
    inverse[name] or= []

    deps = json.dependencies
    if isValid deps, "object"
      Object.keys(deps).forEach (dep) ->

        if inverse[dep]
          inverse[dep].push name
          return

        inverse[dep] = [name]
        return

  return inverse
