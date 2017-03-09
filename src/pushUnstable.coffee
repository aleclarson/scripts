
Repository = require "git-repo"
os = require "os"

pushBranch = require "./utils/pushBranch"

module.exports = (args) ->

  options =
    force: args.force ? args.f
    remote: args.remote or args.r or "origin"
    message: args.m

  repo = Repository process.cwd()

  repo.setBranch "unstable"

  .then ->
    repo.stageFiles "*"
    .then -> repo.isStaged()
    .assert "No changes were staged!"

  .then ->

    message = getDateString()

    if options.message
      message += os.EOL + options.message

    repo.commit message

  .then ->

    log.moat 1
    log.gray "Pushing..."
    log.moat 1

    pushBranch repo.modulePath,
      force: options.force
      remote: options.remote

    .then -> repo.getBranch()
    .then (currentBranch) ->

      repo.getHead currentBranch,
        remote: options.remote
        message: yes

      .then (commit) ->
        log.moat 1
        log.green "Push success! "
        log.gray.dim options.remote + "/" + currentBranch
        log.moat 1
        log.yellow commit.id.slice 0, 7
        log.white " ", commit.message
        log.moat 1

    .fail (error) ->

      repo.resetBranch "HEAD^"
      .then ->

        if error.message is "Must force push to overwrite remote commits!"
          log.moat 1
          log.red "Push failed!"
          log.moat 1
          log.gray.dim "Must use "
          log.white "--force"
          log.gray.dim " when overwriting remote commits!"
          log.moat 1
          return

        throw error

#
# Helpers
#

getDateString = ->

  array = []

  date = new Date

  month = date.getMonth() + 1
  month = "0" + month if month < 10
  array.push month

  day = date.getDate()
  day = "0" + day if day < 10
  array.push "/", day

  array.push "/", date.getFullYear()

  hours = date.getHours() % 12
  array.push " ", if hours is 0 then 12 else hours

  minutes = date.getMinutes()
  minutes = "0" + minutes if minutes < 10
  array.push ":", minutes

  array.push " ", if date.getHours() > 12 then "PM" else "AM"

  return array.join ""
