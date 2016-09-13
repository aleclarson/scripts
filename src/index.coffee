
require "../env"

minimist = require "minimist"
path = require "path"
fs = require "io/sync"

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

  # Get valid script names.
  scripts = fs.readDir __dirname
    .map (script) ->
      ext = path.extname script
      return path.basename script, ext

  Promise.try ->
    index = scripts.indexOf script
    if index < 0
      throw Error """
        Unrecognized script name: '#{script}'

        Valid scripts include:
          #{scripts.join "\n  "}
      """

    start = require "./" + script
    start args

  .fail (error) ->
    log.moat 1
    log.red error.stack
    log.moat 1
    return

  .then process.exit
