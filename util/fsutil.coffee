
fs = require 'fs'

# All of these mkdir_chdir functions are variaions on a theme of creating
# a directory then cd'ing into the newly created directory.

exports.mkdir_chdir1 = (dir) ->
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

exports.mkdir_chdir5 = (dir, callback) ->
  fs.mkdir dir, (err) ->
    if !err
      try
        process.chdir dir
      catch e
        err = e
    callback(err)

