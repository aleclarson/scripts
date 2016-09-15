
path = require "path"
exec = require "exec"

options = {cwd: path.dirname __dirname}

module.exports = ->
  log exec.sync "sudo node postinstall.js", options
