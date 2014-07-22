
fs = require 'fs'
Promise = require 'bluebird'

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

# Explicit deferred object creation.  In practice this method of "promisifying"
# a function is rarely used.
exports.mkdir_chdir5 = (dir) ->
  resolve = reject = null
  promise = new Promise(() -> [resolve, reject] = arguments)
  fs.mkdir dir, (err) ->
    if err
      reject(err)
    else
      process.chdir dir
      resolve()
  promise

# Most of the time it is easier and better to "promisify" from an existing
# node callback style function.
exports.mkdir_chdir6 = Promise.promisify(exports.mkdir_chdir4)


