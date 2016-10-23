
# scripts v2.1.0

```sh
# Add your custom scripts to the 'src' directory.
# Make sure they export a function!
# The command line args are passed to it.
git clone https://github.com/aleclarson/scripts.git

# Install dependencies.
npm install

# Install bin scripts to $(npm bin -g).
# NOTE: This also globally installs this module; using the
#       `__dirname` instead of the package.json "name" field.
sudo node postinstall.js
```

## Symbolic links

```sh
# Link any local dependencies that are missing from $PWD/node_modules
deps link

# To call `deps link` for every recursive dependency
deps link -r

# Links $PWD to $(npm root -g)
deps link -g
```

## Adding dependencies

```sh
# Add a remote dependency.
deps add [pkgs...]

# Add a local dependency.
deps add [pkgs...] --ours
```

## Updating dependencies

```sh
# Find dependencies that could be upgraded.
deps outdated

# Bump a dependency to its latest version.
deps bump [pkg]

# Bump a dependency to a specific version.
deps bump [pkg]@[version]
```
