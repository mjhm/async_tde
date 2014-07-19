

chai = require 'chai'
expect = chai.expect
sinon = require('sinon')
chai.use(require 'sinon-chai')
chai.use(require 'chai-as-promised')

fsutil = require '../../util/fsutil.coffee'
fs = require 'fs'
Q = require 'q'


## These tests focus on a simple asynchronous situation.  The "mkdir_chdir"
## functions create a directory then cd into that directory.  The intent is to
## use the simplest possible non-trivial illustration of the thought processes
## need to think about asynchronous programming. In true Originate style this
## is presented from a TDE (Test Driven Education) perspective :)

describe 'fsutil -', ->

  beforeEach ->
    sinon.stub(process, 'chdir')

  afterEach ->
    fs.mkdir.restore?()
    process.chdir.restore?()


  describe 'mkdir_chdir unit test -', ->

    # This test checks that mkdir and chdir are called.
    # This is not sufficient to test the required behavior
    # which demands that "chdir" is called AFTER "mkdir"
    # has finished creating a directory.
    it 'should call mkdir and chdir', ->
      sinon.stub(fs, 'mkdir').callsArg(1)
      fsutil.mkdir_chdir('/tmp/whatever')
      expect(fs.mkdir).to.be.called
      expect(process.chdir).to.be.called

    # This is better but still incorrect. The stub is assuming that the
    # mkdir's callback happens synchronously.  In practice it happens
    # asynchronously sometime after "nextTick", as the next test will show.
    it 'should call mkdir and chdir', ->
      sinon.stub(fs, 'mkdir').callsArg(1)
      fsutil.mkdir_chdir('/tmp/whatever')
      expect(fs.mkdir).to.be.calledBefore(process.chdir)
      expect(process.chdir).to.be.called


  describe 'mkdir_chdir with real "mkdir" -', ->

    # If we remove the stub and use the real "mkdir" with just a "spy",
    # the same test as above fails.  The failure message says the process.chdir
    # was never called. This is because the test exited before the callback
    # was executed.
    # A proper stub for "mkdir" needs to reflect this order of operations.
    it 'should call mkdir and chdir', ->
      sinon.spy(fs, 'mkdir')
      try  # Delete directory if left over from a previous test run.
        fs.rmdirSync('/tmp/whatever')
      fsutil.mkdir_chdir('/tmp/whatever')
      expect(fs.mkdir).to.be.calledBefore(process.chdir)
      expect(process.chdir).to.be.called


  describe 'mkdir_chdir with better async stubbing of "mkdir" -', ->

    # This still fails but for the same reason as the real "mkdir" test --
    # This is a good thing.  It indicates that the stub and the test are
    # actually doing their job.
    it 'should call mkdir and then chdir asynchronously #1', ->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      fsutil.mkdir_chdir('/tmp/whatever')
      expect(fs.mkdir).to.be.calledBefore(process.chdir)
      expect(process.chdir).to.be.called

    # Finally this is properly stubbed and the test succeeds.  There's still a
    # technical problem. The second "expect" is happening asynchronously,
    # so it is actually being tested after the test has exited.  This is not
    # a practical problem for this test in a Node environment.
    # However if you change "process.nextTick"
    # to a "setTimeout" for just 20 msec (as might happen in a non-Node
    # environment) the callback won't be called at all.
    it 'should call mkdir and then chdir asynchronously #2',  ->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      fsutil.mkdir_chdir('/tmp/whatever')
      expect(fs.mkdir).to.be.calledBefore(process.chdir)
      process.nextTick () ->
        expect(process.chdir).to.be.called

    # The existence of the "done" argument tells the test to not exit early,
    # and it passes the test a function (done) to call.  The test should execute
    # this function when the test knows that it has completed.
    # This tells mocha when it is safe to exit the test and move
    # on to the next.  This test succeeds...
    it 'should call mkdir and then chdir asynchronously #3', (done)->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      fsutil.mkdir_chdir('/tmp/whatever')
      expect(fs.mkdir).to.be.calledBefore(process.chdir)
      process.nextTick () ->
        expect(process.chdir).to.be.called
        done()

    # ... However there is still a subtle problem: "done" is being called from
    # "nextTick".  It is not being triggered by the completion of "mkdir_chdir".
    # In fact this test will indeed fail if the real "mkdir" is used.
    #
    # This finally points out the flaw in the fire-and-forget coding of
    # "mkdir_chdir".  It needs a callback, or event, or promise to somehow
    # tell the rest of the program that it has finished its work.


  describe 'mkdir_chdir2/3 unit tests -', ->

    # Finally a properly stubbed test.  This test fails due to an actual
    # programming error in the coding of "mkdir_chdir2".  Again the test is
    # doing it's job.
    it 'should call mkdir and then chdir asynchronously #4', (done)->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      my_callback = () ->
        expect(process.chdir).to.be.called
        done()
      fsutil.mkdir_chdir2('/tmp/whatever', my_callback)
      expect(fs.mkdir).to.be.calledBefore(process.chdir)

    # ... the code is corrected and the test passes using "mkdir_chdir3".
    it 'should call mkdir and then chdir asynchronously #5', (done)->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      my_callback = () ->
        expect(process.chdir).to.be.called
        done()
      fsutil.mkdir_chdir3('/tmp/whatever', my_callback)
      expect(fs.mkdir).to.be.calledBefore(process.chdir)


  # For completeness we need to check what happens if mkdir fails. Note the
  # new stub for mkdir: ".callsArgWithAsync"
  describe 'mkdir_chdir check for mkdir failure -', ->

    # Since mkdir_chdir3 is not handling the error this test fails.
    # (Once again as it should.)
    it 'should pass the error to the callback and not call chdir #1', (done) ->
      err = new Error('mkdir error')
      sinon.stub(fs, 'mkdir').callsArgWithAsync(1, err)
      my_callback = (err) ->
        expect(process.chdir).not.to.be.called  ## when mkdir fails
        expect(err.message).to.equal('mkdir error')
        done()
      fsutil.mkdir_chdir3('/tmp/whatever', my_callback)
      expect(fs.mkdir).to.be.called

    # ... and the same test on "mkdir_chdir4" with the corrected
    # error handling now passes the test.
    it 'should pass the error to the callback and not call chdir #2', (done) ->
      err = new Error('mkdir error')
      sinon.stub(fs, 'mkdir').callsArgWithAsync(1, err)
      my_callback = (err) ->
        expect(process.chdir).not.to.be.called
        expect(err.message).to.equal('mkdir error')
        done()
      fsutil.mkdir_chdir4('/tmp/whatever', my_callback)
      expect(fs.mkdir).to.be.called


  ## PROMISES

  describe 'mkdir_chdir promise implementations -', ->

    # These test the promise analogs of the callback style mkdir_chdir.
    # Note that the expectations are moved entirely into the fullfilment and
    # rejection handlers.
    it 'should call mkdir and then chdir via the promise', (done)->
      sinon.stub(fs, 'mkdir').callsArgAsync(1)
      fsutil.mkdir_chdir6('/tmp/whatever')
      .then ->
        expect(fs.mkdir).to.be.calledBefore(process.chdir)
        expect(process.chdir).to.be.called
        done()
      .fail ->
        expect('this line will be executed').to.be.false
        done()

    it 'should fail when mkdir fails', (done)->
      sinon.stub(fs, 'mkdir').callsArgWithAsync(1, new Error('mkdir error'))
      fsutil.mkdir_chdir6('/tmp/whatever')
      .then ->
        expect('this line will be executed').to.be.false
        done()
      .fail (err) ->
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
      
      testPromise = fsutil.mkdir_chdir7('/tmp/whatever').then ->
        expect(fs.mkdir).to.be.calledBefore(process.chdir)
        expect(process.chdir).to.be.called
      expect(testPromise).to.eventually.be.resolved

    it 'should fail when mkdir fails', ->
      sinon.stub(fs, 'mkdir').callsArgWithAsync(1, new Error('mkdir error'))

      testPromise = fsutil.mkdir_chdir7('/tmp/whatever')
      testPromise.fail ->
        expect(process.chdir).not.to.be.called
      expect(testPromise).to.eventually.be.rejectedWith(Error)



  describe 'BONUS: mkdir_chdir4 using promise for stubbing -', ->

    # If .callsArgAsync doesn't give you enough control -- for example
    # testing the before and after state of from a callback -- a promise can be
    # used to explicitly specify when a callback is triggered.

    asyncBlocker = null

    beforeEach ->
      asyncBlocker = Q.defer()
      sinon.stub fs, 'mkdir', (path, cb) ->
        asyncBlocker.promise.then () -> cb(null)

    it 'should call mkdir and then chdir asynchronously (promise)', (done)->
      my_callback = () ->
        expect(process.chdir).to.be.called
        done()
      fsutil.mkdir_chdir3('/tmp/whatever', my_callback)
      expect(fs.mkdir).to.be.calledBefore(process.chdir)
      expect(process.chdir).not.to.be.called
      asyncBlocker.resolve()  # Resolving the promise triggers the "then" in the stub.

