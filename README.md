
## scripts v1.2.0

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
