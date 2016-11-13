
Random = require "random"
path = require "path"
git = require "git-utils"

module.exports = (args) ->

  modulePath = process.cwd()
  unless git.isRepo modulePath
    return log.warn "Current directory must be a git repository!"

  git.isClean(modulePath).then (clean) ->
    if clean
    then publishRepo modulePath, args
    else log.warn "Current repo has uncommitted changes!"

publishRepo = (modulePath, args) ->

  newVersion = null
  tmpBranch = Random.id 12

  # 1. Ensure we are on the 'unstable' branch.
  git.getBranch(modulePath).then (branch) ->
    if branch isnt "unstable"
      git.setBranch modulePath, "unstable"

  # 2. Get the new package version.
  .then ->
    jsonPath = path.resolve modulePath, "package.json"
    newVersion = require(jsonPath).version

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

  # 9. Publish the changes on the 'master' branch.
  .then -> git.resetBranch modulePath, "HEAD^^"
  .then ->
    log.moat 1
    log.white "Committing new version: "
    log.green newVersion
    log.moat 1
    git.commit modulePath, newVersion
