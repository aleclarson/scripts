// Generated by CoffeeScript 1.12.4
var assertType, emptyFunction, fs, path, readModules;

emptyFunction = require("emptyFunction");

assertType = require("assertType");

path = require("path");

fs = require("io/sync");

readModules = function(root, filter) {
  var files, mods;
  if (filter == null) {
    filter = emptyFunction.thatReturnsTrue;
  }
  assertType(root, String);
  mods = Object.create(null);
  files = fs.readDir(root);
  files.forEach(function(file) {
    var collision, json, jsonPath;
    file = path.resolve(root, file);
    jsonPath = path.join(file, "package.json");
    if (!fs.exists(jsonPath)) {
      return;
    }
    json = require(jsonPath);
    if (!json.name) {
      return console.warn("Missing module name: '" + file + "'");
    }
    if (collision = mods[json.name]) {
      throw Error("Duplicate module name: '" + json.name + "'\n\n" + file + "\n" + collision.file);
    }
    if (filter(file, json)) {
      return mods[json.name] = {
        file: file,
        json: json
      };
    }
  });
  return mods;
};

module.exports = readModules;