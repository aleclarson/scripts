
Random = require "random"
path = require "path"
git = require "git-utils"

module.exports = (args) ->

  modulePath = process.cwd()
  unless git.isRepo modulePath
    return log.warn "Current directory must be a git repository!"

  git.isClean(modulePath).then (clean) ->
    if clean
    then updatePackageTag modulePath, args
    else log.warn "Current repo has uncommitted changes!"

# Create a tag (or update an existing tag)
# by copying the 'unstable' branch into 'master'.
updatePackageTag = (modulePath, args) ->

  nextVersion = null
  tmpBranch = Random.id 12

  # 1. Ensure we are on the 'unstable' branch.
  git.getBranch(modulePath).then (branch) ->
    if branch isnt "unstable"
      git.setBranch modulePath, "unstable"

  # 2. Get the new package version.
  .then ->
    jsonPath = path.resolve modulePath, "package.json"
    nextVersion = require(jsonPath).version

  # 3. Clone it into a temporary branch.
  .then -> git.setBranch modulePath, tmpBranch, {force: yes}

  # 4. Combine the commit history for cherry-picking.
  .then -> git.resetBranch modulePath, null
  .then -> git.commit modulePath, "combine all commits"

  # 5. Switch back to the 'master' branch.
  .then (tmpCommit) ->
    git.setBranch modulePath, "master"

    # 6. Delete all files in 'master' branch for easier cherry-picking.
    .then -> git.deleteFile modulePath, "*", {force: yes}
    .then -> git.commit modulePath, "delete all files"

    # 7. Cherry-pick the temporary commit.
    .then -> git.pick modulePath, tmpCommit

  # 8. Delete the temporary branch.
  .then -> git.deleteBranch modulePath, tmpBranch

  # 9. Merge the temporary commits.
  .then -> git.resetBranch modulePath, "HEAD^^"

  # 10. Overwrite any duplicate version.
  .then ->
    git.findVersion modulePath, nextVersion
    .then (version) ->

      if version isnt null
        log.moat 1
        log.white "Updating tag: "
        log.green nextVersion
        log.moat 1
        return git.resetBranch modulePath, "HEAD^"

      log.moat 1
      log.white "Creating tag: "
      log.green nextVersion
      log.moat 1
      return

  # 11. Update the 'master' branch.
  .then ->
    git.commit modulePath, nextVersion
    .then -> git.addTag modulePath, nextVersion, {force: yes}
    .then -> git.pushBranch modulePath, {force: yes}

  # 12. End up on the 'unstable' branch.
  .then ->
    git.setBranch modulePath, "unstable"
