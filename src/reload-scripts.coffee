
path = require "path"
exec = require "exec"
fs = require "io/sync"

scriptsDir = path.dirname __dirname
npmBin = exec.sync "sudo npm bin -g"

module.exports = ->

  cachePath = path.join scriptsDir, "scripts.json"

  if fs.exists cachePath
    require(cachePath).forEach (script) ->
      binPath = path.join npmBin, script
      exec.sync "sudo rm #{binPath}"
    fs.remove cachePath

  log exec.sync "sudo node postinstall.js", {cwd: scriptsDir}
