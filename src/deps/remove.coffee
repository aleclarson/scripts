
# deps remove [pkgs...]

# hasKeys = require "hasKeys"
# assert = require "assert"
# isType = require "isType"
#
# module.exports = (options) ->
#
#   options.name = options._.shift()
#   assert isType(options.name, String), "Missing dependency name!"
#
#   if options.all
#     return lotus.Module.crawl()
#     .then (modules) ->
#       Promise.all modules, (module) ->
#         removeDependency module, options
#
#   lotus.Module.load process.cwd()
#   .then (module) ->
#     removeDependency module, options
#
# removeDependency = (module, options) ->
#
#   module.load [ "config" ]
#
#   .then ->
#
#     configKey =
#       if options.dev then "devDependencies"
#       else "dependencies"
#
#     deps = module.config[configKey]
#     return unless deps and deps[options.name]
#
#     log.moat 1
#     log.green.dim lotus.relative module.path + " { "
#     log.white options.name + ": "
#     log.red deps[options.name]
#     log.green.dim " }"
#     log.moat 1
#     return if options.dry
#
#     delete deps[options.name]
#     delete module.config[configKey] unless hasKeys deps
#
#     module.saveConfig()
