
# scripts v3.3.0

Basic "terminal scripts" module (written in `coffee-script`).

### pkg

Scripts in the `pkg` namespace are used for managing directories that contain a `package.json` file.

- **bump**: Increment the current package's version.
- **dirty**: Find packages with uncommitted changes.
- **init**: Create a new package.
- **outdated**: Find packages whose `unstable` branch has commits that `master` does not.
- **publish**: Copy the `master` branch into the `dist` branch, then create a remote tag.
- **tag**: Create/update a tag by copying the `unstable` branch into `master`.

### deps

Scripts in the `deps` namespace are used for managing the `node_modules` directory of a package, and its dependency-related `package.json` fields.

- **bump**: Increment a dependency's version (or add a new dependency).
- **install**: Download any dependencies missing from `node_modules`.
- **link**: Create a symlink to a local dependency.
- **list**: Print the dependencies of a package (or the whole dependency tree).
- **outdated**: Find any dependencies with newer versions.
- **remove**: Remove the given dependencies from the current package.
- **scan**: Scan the source files for `require` calls, then print any unused or missing dependencies.

---

## Installation

```sh
git clone https://github.com/aleclarson/scripts.git
npm install

# Add scripts to your global "bin" directory.
sudo node postinstall.js
```
