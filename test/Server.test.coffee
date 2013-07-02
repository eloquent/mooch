{assert} = require 'chai'
sinon = require 'sinon'
stream = require 'stream'
Server = require '../' + process.env.TEST_ROOT + '/Server'

suite 'Server', ->

  setup ->
    @options =
      consumerKey: 'foo'
      consumerSecret: 'bar'
      port: 111
      twitterUri: 'baz'
    @output = sinon.mock stream.Writable
    @server = new Server @options, @output

  test 'constructor', ->
    assert.strictEqual @server._options, @options
