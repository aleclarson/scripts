
require('./env');

var exec = require('exec');
var path = require('path');
var fs = require('io/sync');

var npmBin = exec.sync('npm bin -g');
var binTemplate = fs.read('templates/bin.js');

var scriptsDir = path.join(__dirname, 'js');
var scriptsInstalled = Object.create(null);

// 1. Install each script into the global NPM bin.
fs.readDir(scriptsDir).forEach(installScript);
log.flush();

// 2. Uninstall any old scripts.
if (fs.exists('./scripts.json')) {
  require('./scripts.json').forEach(function(scriptName) {
    scriptsInstalled[scriptName] || fs.remove(path.join(npmBin, scriptName));
  });
}

// 3. Update scripts.json with the new scripts.
var scriptNames = Object.keys(scriptsInstalled);
if (scriptNames.length) {
  fs.write('./scripts.json', JSON.stringify(scriptNames));
}

function installScript(script) {

  if (script === 'index.js' || script === 'map') {
    return;
  }

  var scriptPath = path.join(scriptsDir, script);
  var isDir = fs.isDir(scriptPath);
  var ext = path.extname(script);
  if (!isDir && ext !== '.js') {
    return;
  }

  var scriptName = path.basename(script, ext);
  var binPath = path.join(npmBin, scriptName);
  if (fs.isFile(binPath)) {
    scriptsInstalled[scriptName] = true;
    return;
  }

  var binScript = binTemplate
    .replace('{{scriptsDir}}', __dirname)
    .replace('{{scriptName}}', scriptName)
    .replace('{{isDir}}', isDir);

  try {
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

  scriptsInstalled[scriptName] = true;
}
