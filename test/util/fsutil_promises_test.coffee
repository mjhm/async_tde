


chai = require 'chai'
expect = chai.expect
sinon = require('sinon')
chai.use(require 'sinon-chai')
chai.use(require 'chai-as-promised')

fsutil = require '../../util/fsutil.coffee'
fs = require 'fs'
Promise = require 'bluebird'

describe.skip 'fsutil_promises -', ->

  beforeEach ->
    sinon.stub(process, 'chdir')

  afterEach ->
    fs.mkdir.restore?()
    process.chdir.restore?()

  ## PROMISES

  describe 'mkdir_chdir promise implementations -', ->

    # These test the promise analogs of the callback style mkdir_chdir.
    # Note that the expectations are moved entirely into the fullfilment and
    # rejection handlers.
    it 'should call mkdir and then chdir via the promise', (done)->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      fsutil.mkdir_chdir5('/tmp/whatever')
        .then ->
          expect(fs.mkdir).to.be.called
          expect(process.chdir).to.be.called
          done()
        .catch ->
          expect('this line will be executed').to.be.false
          done()

    it 'should fail when mkdir fails', (done)->
      sinon.stub(fs, 'mkdir').callsArgWithAsync(1, new Error('mkdir error'))
      fsutil.mkdir_chdir5('/tmp/whatever')
        .then ->
          expect('this line will be executed').to.be.false
          done()
        .catch (err) ->
          expect(process.chdir).not.to.be.called
          expect(err.message).to.equal('mkdir error')
          done()


  describe 'mkdir_chdir promise shortcuts -', ->

    # This uses a few promise specific shortcuts.
    # 1. (done) is omitted from the arg list and no need to call it
    #    when the "then" callbacks exit.  If the return value of
    #    of the "it" block is a promise, mocha is smart enough to wait
    #    for it to be settled. (as of mocha v1.18)
    # 2. The result of "expect" on a promise is a promise and this is carried
    #    through the expectation chain. (This comes from the
    #    "chai-as-promised" module.)  Therefore the final result of an
    #    expectation is a promise which may be handed to mocha as the "it"
    #    return value (see #1).
    # 3. The "eventually" chai token also comes from "chai-as-promised",
    #    it tells the expectation to wait for the promise settle.

    it 'should call mkdir and then chdir via the promise', ->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      
      testPromise = fsutil.mkdir_chdir6('/tmp/whatever').then ->
        expect(fs.mkdir).to.be.called
        expect(process.chdir).to.be.called
      expect(testPromise).to.eventually.be.resolved

    it 'should fail when mkdir fails', ->
      sinon.stub(fs, 'mkdir').callsArgWithAsync(1, new Error('mkdir error'))

      testPromise = fsutil.mkdir_chdir6('/tmp/whatever')
      testPromise.catch ->
        expect(process.chdir).not.to.be.called
      expect(testPromise).to.eventually.be.rejectedWith(Error)



  describe 'BONUS 1: mkdir_chdir4 using promise for stubbing -', ->

    # If .callsArgAsync doesn't give you enough control -- for example
    # testing the before and after state of from a callback -- a promise can be
    # used to explicitly specify when a callback is triggered.

    resolve = null

    beforeEach ->
      asyncBlocker = new Promise((r) -> resolve = r)
      sinon.stub fs, 'mkdir', (path, cb) ->
        asyncBlocker.then () -> cb(null)

    it 'should call mkdir and then chdir asynchronously (promise)', (done)->
      my_callback = () ->
        expect(process.chdir).to.be.called
        done()
      fsutil.mkdir_chdir3('/tmp/whatever', my_callback)
      expect(fs.mkdir).to.be.called
      expect(process.chdir).not.to.be.called
      resolve()  # Resolving the promise triggers the "then" in the stub.



  describe 'BONUS 2: ConfigPromise', ->
    it 'should set and get config', ->
      cp = new fsutil.ConfigPromise()
      testConfig = 'whatever'
      expect(cp.getConfig(), 'before setting').to.be.null
      cp.setConfig(testConfig)
      cp.then () ->
        expect(cp.getConfig(), 'after setting').to.equal(testConfig)


    it 'should carry the config through chained promises', ->
      testConfig = 'whatever'
      cp = new fsutil.ConfigPromise()
      finalPromise = cp.then () ->
        expect(@getConfig(), 'in first chained promise').to.equal(testConfig)
      .then () ->
        expect(@getConfig(), 'in second chained promise').to.equal(testConfig)
      finalPromise.setConfig(testConfig)
      expect(finalPromise).to.eventually.be.resolved
      finalPromise


  describe 'BONUS 3: dependency injection following reader monad pattern -', ->

    fs_local = {
      mkdir: sinon.stub().callsArgAsync(1)
    }
    Promise.promisifyAll(fs_local)


    it 'should call mkdir with injected stub -- setConfig first', () ->

      testPromise = fsutil.fsConfigPromise.setConfig(fs_local)
        .then () ->
          fsutil.mkdir_chdir7('/tmp/whatever')
        .then () ->
          expect(fs_local.mkdir).to.be.called
          expect(process.chdir).to.be.called
      expect(testPromise).to.eventually.be.resolved


    it 'should call mkdir with injected stub -- setConfig later', () ->
      testPromise = fsutil.mkdir_chdir7('/tmp/whatever')
        .then () ->
          expect(fs_local.mkdir).to.be.calledBefore(process.chdir)
          expect(process.chdir).to.be.called
        expect(testPromise).to.eventually.be.resolved
      testPromise.setConfig(fs_local)



