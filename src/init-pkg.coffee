
mergeDefaults = require "mergeDefaults"
path = require "path"
fs = require "io/sync"

stabilityLevels =
  experimental: "![experimental](https://img.shields.io/badge/stability-experimental-EC5315.svg?style=flat)"
  stable: "![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)"
  locked: "![locked](https://img.shields.io/badge/stability-locked-0084B6.svg?style=flat)"

module.exports = (args) ->

  moduleName = args._[0]
  if not moduleName
    log.warn "Must provide a module name!"
    return

  modulePath = path.resolve moduleName
  if fs.exists modulePath
    log.warn "Module already exists:\n  #{modulePath}"
    return

  json =
    name: moduleName
    description: args.d or args.description
    version: args.v or args.version or "0.0.1"
    main: args.m or args.main

  if json.description and typeof json.description isnt "string"
    log.warn "--description must provide a string!"
    return

  if typeof json.version isnt "string"
    log.warn "--version must provide a string!"
    return

  if json.main and typeof json.main isnt "string"
    log.warn "--main must provide a string!"
    return

  ignoredPaths = ["node_modules/"]

  if args.c or args.coffee
    json.main ?= "js/index"
    mergeDefaults json, require "../templates/coffee.package.json"
    json.plugins = ["lotus-coffee"]
    ignoredPaths.push "js/"

  stabilityLevel =
    if stability = args.s or args.stability
    then stabilityLevels[stability]
    else ""

  if stabilityLevel is undefined
    log.warn "Invalid stability level: '#{stability}'"
    return

  #
  # File creation phase
  #

  fs.writeDir modulePath
  log.it "Creating directory: '#{modulePath}'"

  srcPath = path.join modulePath, "src"
  fs.writeDir srcPath
  log.it "Creating directory: '#{srcPath}'"

  specPath = path.join modulePath, "spec"
  fs.writeDir specPath
  log.it "Creating directory: '#{specPath}'"

  jsonPath = path.join modulePath, "package.json"
  fs.write jsonPath, JSON.stringify json, null, 2
  log.it "Creating file: '#{jsonPath}'"

  ignorePath = path.join modulePath, ".gitignore"
  fs.write ignorePath, ignoredPaths.join log.ln
  log.it "Creating file: '#{ignorePath}'"

  licensePath = path.join modulePath, "LICENSE"
  licenseTemplatePath = path.join __dirname, "../templates/LICENSE"
  fs.write licensePath, fs.read licenseTemplatePath
  log.it "Creating file: '#{licensePath}'"

  readmePath = path.join modulePath, "README.md"
  fs.write readmePath, "\n# #{json.name} v#{json.version} #{stabilityLevel}\n"
  log.it "Creating file: '#{readmePath}'"
  return
