
## scripts v0.0.3

```sh
npm i -g aleclarson/scripts#0.0.3

# Overwrites 'manifest.json' in the package's root directory.
scripts read-deps path/to/package

# Reads the 'manifest.json' of the package and
# creates symbolic links for any local dependencies.
# Specify --refresh to clear old dependencies.
scripts link-deps path/to/package

# Reads the 'manifest.json' of the package and
# uses NPM to install any remote dependencies.
scripts install-deps path/to/package
```
