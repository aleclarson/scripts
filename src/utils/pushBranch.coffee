
prompt = require "prompt"
git = require "git-utils"

module.exports = (modulePath, options = {}) ->

  options.remote ?= "origin"

  git.pushBranch modulePath, options

  .fail (error) ->

    unless upstreamError.test error.message
      throw error

    log.moat 1
    log.yellow "WARN: "
    log.white "The current branch has no upstream branch!"
    log.moat 1
    log.gray "Should "
    log.yellow options.remote + "/unstable"
    log.gray " be the upstream branch? "

    prompt.async {bool: true}
    .then (setUpstream) ->
      log.moat 1

      unless setUpstream
        throw Error "Cannot push local branch without an upstream branch!"

      options.upstream = true
      return git.pushBranch modulePath, options

upstreamError = /The current branch [^\s]+ has no upstream branch/

