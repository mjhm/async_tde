
fs = require 'fs'
Q = require 'q'

# All of these mkdir_chdir functions are variaions on a theme of creating
# a directory then cd'ing into the newly created directory.

exports.mkdir_chdir = (dir) ->
  fs.mkdir dir, ->
    process.chdir dir

exports.mkdir_chdir2 = (dir, callback) ->
  fs.mkdir dir, ->
    process.chdir dir
  callback()

exports.mkdir_chdir3 = (dir, callback) ->
  fs.mkdir dir, () ->
    process.chdir dir
    callback()

exports.mkdir_chdir4 = (dir, callback) ->
  fs.mkdir dir, (err) ->
    if !err
      process.chdir dir
    callback(err)


# The following are equivalent formulations of mkdir_chdir using "q" promises.

# Explicit Deferred object creation.
exports.mkdir_chdir5 = (dir) ->
  deferred = Q.defer()
  fs.mkdir dir, (err) ->
    process.chdir dir
    if err
      deferred.reject(err)
    else
      process.chdir dir
      deferred.resolve()
  deferred.promise

# Two uses of the Q.nfcall shortcuts for Node style functions with callbacks.
exports.mkdir_chdir6 = (dir) ->
  Q.nfcall(fs.mkdir, dir).then () ->
    process.chdir dir

exports.mkdir_chdir7 = (dir) ->
  Q.nfcall(exports.mkdir_chdir4, dir)


