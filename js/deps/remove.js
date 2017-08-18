// Generated by CoffeeScript 1.12.4
var fs, hasKeys, path;

hasKeys = require("hasKeys");

path = require("path");

fs = require("io/sync");

module.exports = function(args) {
  var dep, deps, devDeps, i, installedPath, json, jsonPath, len, modulePath, ref;
  if (!args._.length) {
    return log.warn("Must provide at least one dependency name!");
  }
  modulePath = process.cwd();
  jsonPath = path.resolve(modulePath, "package.json");
  if (!fs.isFile(jsonPath)) {
    return log.warn("Must be in a directory with a 'package.json' file!");
  }
  json = require(jsonPath);
  deps = json.dependencies || {};
  devDeps = json.devDependencies || {};
  ref = args._;
  for (i = 0, len = ref.length; i < len; i++) {
    dep = ref[i];
    delete deps[dep];
    delete devDeps[dep];
    installedPath = path.resolve(modulePath, "node_modules", dep);
    if (fs.exists(installedPath)) {
      log.moat(1);
      log.red("Removing: ");
      log.white(path.relative(modulePath, installedPath));
      log.moat(1);
      log.flush();
      fs.remove(installedPath);
    }
  }
  if (!hasKeys(deps)) {
    delete json.dependencies;
  }
  if (!hasKeys(devDeps)) {
    delete json.devDependencies;
  }
  json = JSON.stringify(json, null, 2);
  fs.write(jsonPath, json + log.ln);
};