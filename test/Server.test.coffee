{assert, expect} = require 'chai'
http = require 'http'
request = require 'request'
sinon = require 'sinon'
stream = require 'stream'
Server = require '../' + process.env.TEST_ROOT + '/Server'

suite 'Server', ->

  setup ->
    @consumerKey = 'xvz1evFS4wEEPTGEFPHBog'
    @consumerSecret = 'L8qq9PZyRg6ieKGEKhZolGC0vJWLw8iEJ88DRdyOg'
    @options =
      consumerKey: @consumerKey
      consumerSecret: @consumerSecret
      port: 111
      twitterUri: 'http://api.example.org'

    @request = sinon.stub()
    @httpServer = sinon.createStubInstance http.Server
    @http =
      createServer: sinon.stub().returns @httpServer
    @output =
      write: sinon.spy()

    @server = new Server @options, @request, @http, @output

    @obtainTokenOptions =
        uri: 'http://api.example.org/oauth2/token'
        method: 'POST'
        headers:
          authorization: 'Basic eHZ6MWV2RlM0d0VFUFRHRUZQSEJvZzpMOHFxOVBaeVJnNmllS0dFS2hab2xHQzB2SldMdzhpRUo4OERSZHlPZw=='
        form:
          grant_type: 'client_credentials'

  suite '#constructor()', ->

    test 'members', ->
      assert.strictEqual @server._options, @options
      assert.strictEqual @server._request, @request
      assert.strictEqual @server._http, @http
      assert.strictEqual @server._output, @output

    test 'member defaults', ->
      @options =
        consumerKey: 'xvz1evFS4wEEPTGEFPHBog'
        consumerSecret: 'L8qq9PZyRg6ieKGEKhZolGC0vJWLw8iEJ88DRdyOg'
      @server = new Server @options

      assert.strictEqual @server._options.port, 8000
      assert.strictEqual @server._options.twitterUri, 'https://api.twitter.com'
      assert.strictEqual @server._request, request
      assert.strictEqual @server._http, http
      assert.strictEqual @server._output, process.stdout

    test 'requires consumer key', ->
      expect(=> new Server consumerSecret: 'L8qq9PZyRg6ieKGEKhZolGC0vJWLw8iEJ88DRdyOg').to.throw 'Consumer key is required.'

    test 'requires consumer secret', ->
      expect(=> new Server consumerKey: 'xvz1evFS4wEEPTGEFPHBog').to.throw 'Consumer secret is required.'

  suite '#start()', ->

    test 'obtains a token before handling requests', (done) ->
      response =
        statusCode: 200
      responseBody = '{"token_type":"bearer","access_token":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}'
      @request.callsArgOnWith 1, @server, null, response, responseBody

      @server.start (error) =>
        assert.isNull error
        sinon.assert.calledOnce @request
        sinon.assert.calledOn @request, @server
        sinon.assert.calledWithExactly @request, @obtainTokenOptions, sinon.match.func
        sinon.assert.calledOnce @http.createServer
        sinon.assert.calledWithExactly @http.createServer, sinon.match.func
        sinon.assert.calledOnce @httpServer.listen
        sinon.assert.calledWithExactly @httpServer.listen, 111
        sinon.assert.callOrder \
          @output.write.withArgs('Obtaining bearer token... '),
          @request,
          @output.write.withArgs('done.\n'),
          @http.createServer
        done()

    test 'returns an error when obtaining a token results in an HTTP error', (done) ->
      response =
        statusCode: 500
      responseBody = 'Internal server error.'
      @request.callsArgOnWith 1, @server, null, response, responseBody

      @server.start (error) =>
        assert.strictEqual response, error
        sinon.assert.calledOnce @request
        sinon.assert.calledOn @request, @server
        sinon.assert.calledWithExactly @request, @obtainTokenOptions, sinon.match.func
        sinon.assert.notCalled @http.createServer
        sinon.assert.callOrder \
          @output.write.withArgs('Obtaining bearer token... '),
          @request,
          @output.write.withArgs('HTTP error (500).\n')
        done()

    test 'returns an error when obtaining a token results in an error', (done) ->
      @request.callsArgOnWith 1, @server, 'error', null, null

      @server.start (error) =>
        assert.strictEqual 'error', error
        sinon.assert.calledOnce @request
        sinon.assert.calledOn @request, @server
        sinon.assert.calledWithExactly @request, @obtainTokenOptions, sinon.match.func
        sinon.assert.notCalled @http.createServer
        sinon.assert.callOrder \
          @output.write.withArgs('Obtaining bearer token... '),
          @request,
          @output.write.withArgs('unknown error.\n')
        done()

