// Generated by CoffeeScript 1.12.4
var exec, fetchLatestVersion, fs, latestVersions, npmRoot, path, printOutdated, semver, verifyVersion;

semver = require("node-semver");

exec = require("exec");

path = require("path");

fs = require("io/sync");

module.exports = function(args) {
  var file, files, i, len, modulePath;
  if (args.scan) {
    files = fs.readDir(".");
    for (i = 0, len = files.length; i < len; i++) {
      file = files[i];
      modulePath = path.resolve(file);
      printOutdated(modulePath, args);
    }
    return;
  }
  modulePath = path.resolve(args._[0] || process.cwd());
  printOutdated(modulePath, args);
};

printOutdated = function(modulePath, args) {
  var dep, deps, i, json, jsonPath, latestVersion, len, outdated, ref, ref1, repo, version;
  jsonPath = path.resolve(modulePath, "package.json");
  if (!fs.exists(jsonPath)) {
    args.scan || log.warn("Missing package.json");
    return;
  }
  json = require(jsonPath);
  if (!(deps = json.dependencies)) {
    args.scan || log.warn("No dependencies exist");
    return;
  }
  outdated = [];
  for (dep in deps) {
    version = deps[dep];
    ref = version.split("#"), repo = ref[0], version = ref[1];
    if (!verifyVersion(version)) {
      continue;
    }
    latestVersion = fetchLatestVersion(dep);
    if (!verifyVersion(latestVersion)) {
      continue;
    }
    if (!semver.gt(version, latestVersion)) {
      if (!semver.gt(latestVersion, version)) {
        continue;
      }
    }
    outdated.push({
      dep: dep,
      version: version,
      latestVersion: latestVersion
    });
  }
  if (!outdated.length) {
    return;
  }
  if (args.scan) {
    log.moat(1);
    log.white(path.basename(modulePath));
    log.plusIndent(2);
  }
  for (i = 0, len = outdated.length; i < len; i++) {
    ref1 = outdated[i], dep = ref1.dep, version = ref1.version, latestVersion = ref1.latestVersion;
    log.moat(1);
    log.white(dep);
    log.gray(" current: ");
    log.red(version);
    log.gray(" latest: ");
    log.yellow(latestVersion);
    log.moat(1);
  }
  if (args.scan) {
    log.popIndent();
  }
};

npmRoot = exec.sync("npm root -g");

latestVersions = Object.create(null);

verifyVersion = function(version) {
  if (version) {
    if (semver.valid(version)) {
      return true;
    }
    if (semver.validRange(version)) {
      return true;
    }
  }
  return false;
};

fetchLatestVersion = function(moduleName) {
  var json, jsonPath, version;
  if (version = latestVersions[moduleName]) {
    return version;
  }
  jsonPath = path.join(npmRoot, moduleName, "package.json");
  if (!fs.exists(jsonPath)) {
    return null;
  }
  json = require(jsonPath);
  latestVersions[moduleName] = json.version;
  return json.version;
};