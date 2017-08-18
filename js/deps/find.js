// Generated by CoffeeScript 1.12.4
var hasKeys, readModules;

hasKeys = require("hasKeys");

readModules = require("../utils/readModules");

module.exports = function(args) {
  var dependencies, deps, mod, mods, moduleName, name, version;
  moduleName = args._.shift();
  deps = Object.create(null);
  mods = readModules(process.cwd());
  for (name in mods) {
    mod = mods[name];
    dependencies = mod.json.dependencies;
    if (!dependencies) {
      continue;
    }
    if (version = dependencies[moduleName]) {
      if (0 <= version.indexOf("#")) {
        version = version.split("#").pop();
      }
      deps[name] = version;
    }
  }
  log.moat(1);
  log.white("Modules that depend on ");
  log.green(moduleName);
  log.moat(1);
  log.plusIndent(2);
  if (!hasKeys(deps)) {
    log.gray("No modules were found.");
    log.moat(1);
    return;
  }
  for (name in deps) {
    version = deps[name];
    log.white(name + " ");
    log.yellow(version);
    log.moat(1);
  }
};