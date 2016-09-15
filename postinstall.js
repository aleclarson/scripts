
require('./env');

var exec = require('exec');
var path = require('path');
var fs = require('io/sync');

// 1. Install 'scripts' into the global NPM root.
var npmRoot = exec.sync('npm root -g');
var globalPath = path.join(npmRoot, path.basename(__dirname));
fs.writeLink(globalPath, __dirname);

var npmBin = exec.sync('npm bin -g');
var binTemplate = fs.read('templates/bin.js');

// 2. Install each script into the global NPM bin.
fs.match('js/!(index).js').forEach(function(script) {
  var ext = path.extname(script);
  var name = path.basename(script, ext);
  var binPath = path.join(npmBin, name);
  var binScript = binTemplate.replace("{{script}}", name);
  try {
    fs.isLink(binPath) && fs.remove(binPath);
    fs.write(binPath, binScript);
    fs.setMode(binPath, '755');
  } catch (error) {
    log.moat(1);
    log.red(error.stack);
    log.warn('Failed to write to:\n  ' + binPath);
    log.flush();
    return process.exit();
  }
  log.moat(1);
  log.white('Created script at bin path:\n  ' + binPath);
  log.moat(1);
});
log.flush();
