
path = require "path"
fs = require "fsx"

stabilityLevels =
  experimental: "![experimental](https://img.shields.io/badge/stability-experimental-EC5315.svg?style=flat)"
  stable: "![stable](https://img.shields.io/badge/stability-stable-4EBA0F.svg?style=flat)"
  locked: "![locked](https://img.shields.io/badge/stability-locked-0084B6.svg?style=flat)"

module.exports = (args) ->

  if args.help
    log help
    return

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

  ignoredPaths = ["/node_modules/"]

  if args.c or args.coffee
    ignoredPaths.push "/js/"
    json.main ?= "js/index"
    json.scripts =
      build: "coffee-build src -o js"
      prepublishOnly: "prepv -i || true"
    json.devDependencies =
      "coffeescript": "^2.3.0"
      "wch-coffee": "*"

  stabilityLevel =
    if stability = args.s or args.stability
    then stabilityLevels[stability]
    else ""

  if stabilityLevel is undefined
    log.warn """
      Invalid stability level: '#{stability}'

      Valid values:
        #{Object.keys(stabilityLevels).join('\n  ')}
    """
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
  jsonString = JSON.stringify json, null, 2
  fs.writeFile jsonPath, jsonString + log.ln
  log.it "Creating file: '#{jsonPath}'"

  ignorePath = path.join modulePath, ".gitignore"
  fs.writeFile ignorePath, ignoredPaths.join log.ln
  log.it "Creating file: '#{ignorePath}'"

  if args.c or args.coffee
    ignorePath = path.join modulePath, ".npmignore"
    log.it "Creating file: '#{ignorePath}'"
    fs.writeFile ignorePath, """
      !/js/
      /src/
      /spec/
    """

  licensePath = path.join modulePath, "LICENSE"
  licenseTemplatePath = path.resolve __dirname, "../../templates/LICENSE"
  fs.writeFile licensePath, fs.readFile licenseTemplatePath
  log.it "Creating file: '#{licensePath}'"

  readmePath = path.join modulePath, "README.md"
  fs.writeFile readmePath, "\n# #{json.name} v#{json.version} #{stabilityLevel}\n"
  log.it "Creating file: '#{readmePath}'"
  return

help = """
  Options:

    --coffee -c
      Transpile from 'src' to 'js' directory

    --version -v
      Bump to a specific version

    --description -d
      The "description" field of package.json

    --main -m
      The "main" field of package.json

    --stability -s
      Must equal "experimental", "stable", or "locked"
"""
