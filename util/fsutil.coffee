
fs = require 'fs'
Promise = require 'bluebird'

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

# Most of the time it's better to just "promisify" an existing
# node callback style function.
exports.mkdir_chdir6 = Promise.promisify(exports.mkdir_chdir4)



class ConfigPromise

  constructor: () ->
    myResolve = null
    myPromise = new Promise((resolver) -> myResolve = resolver)
    myConfig = {_config: {}}
    configPromise = myPromise.bind(myConfig)

    configPromise.setConfig = (config) ->
      myConfig._config = config
      myResolve(config)
      configPromise

    configPromise.getConfig = () ->
      if configPromise.isResolved()
        myConfig._config
      else
        null

    myConfig.getConfig = () -> myConfig._config
    myConfig.setConfig = configPromise.setConfig

    return configPromise

exports.ConfigPromise = ConfigPromise

Promise.prototype.setConfig = (config) ->
  @_boundTo?.setConfig?(config)
  @


exports.fsConfigPromise = new ConfigPromise()


exports.mkdir_chdir7 = (dir) ->
  exports.fsConfigPromise
    .then () ->
      fs_local = @getConfig()
      fs_local.mkdirAsync(dir)
    .then () ->
      process.chdir(dir)




