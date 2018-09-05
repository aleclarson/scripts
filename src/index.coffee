
minimist = require "minimist"
isValid = require "isValid"
path = require "path"
log = require "log"
fs = require "fsx"

module.exports = (script, args = []) ->

  log.indent = 2
  log.moat 1

  timeStart = Date.now()
  {exit} = process
  process.exit = ->
    log.onceFlushed ->
      timeEnd = Date.now()
      log.moat 1
      log.gray.dim "Exiting after #{timeEnd - timeStart}ms..."
      log.moat 1
      log.flush()
      exit.call process
    return

  # Parse command line arguments.
  args = args.concat process.argv.slice 2
  args = minimist args

  # Check if the script name is valid.
  scriptsInstalled = require "../scripts.json"
  index = scriptsInstalled.indexOf script
  if index < 0
    return log.warn """
      Unrecognized script name: '#{script}'

      Valid scripts include:
        #{scriptsInstalled.join "\n  "}
    """

  Promise.resolve().then ->
    start = require "./" + script

    if typeof start == "function"
      return start args

    if isValid start, "object"
      commands = []
      while args._.length
        commands.push command = args._.shift()

        if typeof start[command] == "function"
          start = start[command]()
          if typeof start == "function"
            return start args

          break if !isValid start, "object"

      throw Error "Unrecognized command: " + commands.join " "

    throw Error "Script must return a function or object: #{script}"

  .catch (error) ->
    log.moat 1
    log.red error.stack
    log.moat 1
    return

  .then -> process.exit()
