// Generated by CoffeeScript 1.12.4
var Finder, OneOf, config, emptyFunction, findRequire, findRoot, fs, glob, hasKeys, ignored, nodePaths, path, printResults, resolvePath;

resolvePath = require("resolve").resolvePath;

emptyFunction = require("emptyFunction");

nodePaths = require("node-paths");

hasKeys = require("hasKeys");

Finder = require("finder");

OneOf = require("OneOf");

glob = require("globby");

path = require("path");

fs = require("io/sync");

config = require("../../config.json");

ignored = OneOf(config.ignore);

findRequire = Finder({
  regex: /(\brequire\s*?\(\s*?)(['"])([^'"]+)(\2\s*?\))/g,
  group: 3
});

module.exports = function(args) {
  var currentDeps, dep, depParts, depPath, deps, devDeps, file, files, foundDeps, i, j, js, json, jsonPath, len, len1, missingDeps, modulePath, printDependers, push, unexpectedDeps, unusedDeps;
  if (!args._.length) {
    return log.warn("Must provide a module path!");
  }
  modulePath = path.resolve(args._.shift());
  jsonPath = path.join(modulePath, "package.json");
  json = require(jsonPath);
  if (ignored.test(json.name)) {
    return;
  }
  currentDeps = json.dependencies || {};
  devDeps = json.devDependencies || {};
  foundDeps = Object.create(null);
  missingDeps = Object.create(null);
  unexpectedDeps = Object.create(null);
  push = function(obj, key, value) {
    if (obj[key]) {
      return obj[key].push(value);
    } else {
      return obj[key] = [value];
    }
  };
  files = glob.sync(modulePath + "/**/*.js");
  for (i = 0, len = files.length; i < len; i++) {
    file = files[i];
    if (/\/node_modules\//.test(file)) {
      continue;
    }
    if (modulePath !== findRoot(file)) {
      continue;
    }
    js = fs.read(file);
    deps = findRequire.all(js);
    for (j = 0, len1 = deps.length; j < len1; j++) {
      dep = deps[j];
      if (~dep.indexOf("!")) {
        continue;
      }
      if (dep[0] === ".") {
        depPath = resolvePath(dep, {
          parent: path.dirname(file)
        });
        depPath || push(missingDeps, dep, file);
        continue;
      }
      depParts = dep.split("/");
      if (depParts.length) {
        dep = depParts[0];
      }
      if (!(devDeps[dep] || ~nodePaths.indexOf(dep))) {
        if (currentDeps[dep]) {
          push(foundDeps, dep, file);
        } else {
          push(unexpectedDeps, dep, file);
        }
      }
    }
  }
  unusedDeps = Object.create(null);
  Object.keys(currentDeps).forEach(function(dep) {
    return foundDeps[dep] || (unusedDeps[dep] = true);
  });
  printDependers = function(dep, dependers) {
    var k, len2;
    log.plusIndent(2);
    for (k = 0, len2 = dependers.length; k < len2; k++) {
      file = dependers[k];
      log.moat(0);
      log.gray.dim(path.relative(modulePath, file));
    }
    return log.popIndent();
  };
  printResults("Missing relatives: ", missingDeps, printDependers);
  printResults("Unexpected absolutes: ", unexpectedDeps, printDependers);
  return printResults("Unused absolutes: ", unusedDeps);
};

findRoot = function(filePath) {
  var dir;
  dir = path.dirname(filePath);
  while (!fs.isFile(path.join(dir, "package.json"))) {
    dir = path.dirname(dir);
  }
  return dir;
};

printResults = function(title, deps, iterator) {
  var dep, dependers;
  if (iterator == null) {
    iterator = emptyFunction;
  }
  if (!hasKeys(deps)) {
    return;
  }
  log.moat(1);
  log.yellow(title);
  log.plusIndent(2);
  for (dep in deps) {
    dependers = deps[dep];
    log.moat(1);
    log.white(dep);
    log.moat(0);
    iterator(dep, dependers);
    log.moat(1);
  }
  log.popIndent();
  return log.moat(1);
};
