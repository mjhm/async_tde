
chai = require 'chai'
expect = chai.expect
sinon = require('sinon')
chai.use(require 'sinon-chai')

fsutil = require '../../util/fsutil.coffee'
fs = require 'fs'

describe 'fsutil -', ->

  beforeEach ->
    sinon.stub(process, 'chdir')
    try  # Only needed for the "real" mkdir demonstration tests.
      fs.rmdirSync('/tmp/whatever')

  afterEach ->
    fs.mkdir.restore?()
    process.chdir.restore?()

  describe 'mkdir_chdir1 unit test -', ->

    ## Test that ignores mkdir_chdir's async behavior.
    it 'should call mkdir and chdir', ->
      sinon.stub(fs, 'mkdir').callsArg(1)
      fsutil.mkdir_chdir1('/tmp/whatever')
      expect(fs.mkdir).to.be.called
      expect(process.chdir).to.be.called


    ## Test with real "mkdir" -- Fail
    it 'should call real mkdir and then chdir (test fails)', ->
      sinon.spy(fs, 'mkdir')
      fsutil.mkdir_chdir1('/tmp/whatever')
      expect(fs.mkdir).to.be.called
      expect(process.chdir).to.be.called


    ## Async Stub -- Fails (and it's a good thing)
    it 'should call stubbed mkdir and then chdir asynchronously #1 (test fails)', ->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      fsutil.mkdir_chdir1('/tmp/whatever')
      expect(fs.mkdir).to.be.called
      expect(process.chdir).to.be.called

    ## Final check after nextTick -- trying expectation in nextTick, with both
    ## the stubbed mkdir and the real mkdir
    it 'should call stubbed mkdir and then chdir asynchronously #2a',  ->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      fsutil.mkdir_chdir1('/tmp/whatever')
      expect(fs.mkdir).to.be.called
      process.nextTick () ->
        expect(process.chdir).to.be.called

    ## This test fails badly enough to affect successive tests, and emphasizes
    ## that the use of "nextTick" is a bad practice for testing async expectations.
    it.skip 'should call real mkdir and then chdir asynchronously #2b (test fails)',  ->
      sinon.spy(fs, 'mkdir')
      fsutil.mkdir_chdir1('/tmp/whatever')
      expect(fs.mkdir).to.be.called
      process.nextTick () ->
        expect(process.chdir).to.be.called

  describe 'mkdir_chdir2 unit test -', ->

    ## Testing mkdir_chdir2 which with mistake in using callback
    it 'should call mkdir and then chdir asynchronously #3 (test fails)', ->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      my_callback = () ->
        expect(process.chdir).to.be.called
      fsutil.mkdir_chdir2('/tmp/whatever', my_callback)
      expect(fs.mkdir).to.be.called


  describe 'mkdir_chdir3 unit tests -', ->

    ## Final test for normal behavior of mkdir_chdir
    it 'should call mkdir and then chdir asynchronously', (done) ->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      my_callback = () ->
        expect(process.chdir).to.be.called
        done()
      fsutil.mkdir_chdir3('/tmp/whatever', my_callback)
      expect(process.chdir).not.to.be.called
      expect(fs.mkdir).to.be.called


    ## Error Pass Through Test -- Fails for mkdir_chdir3
    it 'should send the error to the callback and not call chdir (test fails)', (done) ->
      mkdirErr = new Error('mkdir error')
      sinon.stub(fs, 'mkdir').callsArgWithAsync(1, mkdirErr)
      my_callback = (err) ->
        expect(process.chdir).not.to.be.called  ## when mkdir fails
        expect(err.message).to.equal('mkdir error')
        done()
      fsutil.mkdir_chdir3('/tmp/whatever', my_callback)


  ## All of the corrected tests for the corrected function.
  describe 'mkdir_chdir5 unit tests -', ->

    it 'should call mkdir and then chdir asynchronously', (done) ->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      my_callback = () ->
        expect(process.chdir).to.be.called
        done()
      fsutil.mkdir_chdir5('/tmp/whatever', my_callback)
      expect(process.chdir).not.to.be.called
      expect(fs.mkdir).to.be.called


    it 'should send the error to the callback and not call chdir', (done) ->
      mkdirErr = new Error('mkdir error')
      sinon.stub(fs, 'mkdir').callsArgWithAsync(1, mkdirErr)
      my_callback = (err) ->
        expect(process.chdir).not.to.be.called  ## when mkdir fails
        expect(err.message).to.equal('mkdir error')
        done()
      fsutil.mkdir_chdir5('/tmp/whatever', my_callback)


    it 'should convert exception from chdir to a callback argument', (done) ->
      sinon.stub(fs, 'mkdir').callsArgWithAsync(1)
      process.chdir.restore?()
      sinon.stub(process, 'chdir').throws()
      my_callback = (err) ->
        expect(process.chdir).threw
        done()
      fsutil.mkdir_chdir5('/tmp/whatever', my_callback)


  describe 'BONUS: mkdir_chdir5 using promise for stubbing -', ->

    # If .callsArgAsync doesn't give you enough control -- for example
    # testing the before and after state of from a callback -- a promise can be
    # used to explicitly specify when a callback is triggered.

    Promise = require('bluebird')

    ## This will hold the asyncBlocker's resolving function.
    resolve = null

    beforeEach ->
      asyncBlocker = new Promise((r) -> resolve = r)
      sinon.stub fs, 'mkdir', (path, cb) ->
        ## after the promise is resolved the callback is called.
        asyncBlocker.then () -> cb(null)

    it 'should call mkdir and then chdir asynchronously (promise)', (done)->
      my_callback = () ->
        expect(process.chdir).to.be.called
        done()
      fsutil.mkdir_chdir5('/tmp/whatever', my_callback)
      expect(fs.mkdir).to.be.called
      expect(process.chdir).not.to.be.called
      resolve()  # Resolving the promise triggers the "then" in the stub.

