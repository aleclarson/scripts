
hasKeys = require "hasKeys"
path = require "path"
fs = require "io/sync"

module.exports = (args) ->

  if not args._.length
    return log.warn "Must provide at least one dependency name!"

  modulePath = process.cwd()

  jsonPath = path.resolve modulePath, "package.json"
  if not fs.isFile jsonPath
    return log.warn "Must be in a directory with a 'package.json' file!"

  json = require jsonPath
  deps = json.dependencies or {}
  devDeps = json.devDependencies or {}

  for dep in args._
    delete deps[dep]
    delete devDeps[dep]
    installedPath = path.resolve modulePath, "node_modules", dep
    if fs.exists installedPath
      log.moat 1
      log.red "Removing: "
      log.white path.relative modulePath, installedPath
      log.moat 1
      log.flush()
      fs.remove installedPath

  unless hasKeys deps
    delete json.dependencies

  unless hasKeys devDeps
    delete json.devDependencies

  json = JSON.stringify json, null, 2
  fs.write jsonPath, json + log.ln
  return
