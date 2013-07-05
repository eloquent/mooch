###
This file is part of the Mooch package.

Copyright © 2013 Erin Millard

For the full copyright and license information, please view the LICENSE
file that was distributed with this source code.
###

{assert, expect} = require 'chai'
http = require 'http'
portfinder = require 'portfinder'
request = require 'request'
sinon = require 'sinon'
util = require 'util'
Logger = require '../' + process.env.TEST_ROOT + '/Logger'
Server = require '../' + process.env.TEST_ROOT + '/Server'

suite 'Server', =>

  setup =>
    @consumerKey = 'xvz1evFS4wEEPTGEFPHBog'
    @consumerSecret = 'L8qq9PZyRg6ieKGEKhZolGC0vJWLw8iEJ88DRdyOg'
    @options =
      consumerKey: @consumerKey
      consumerSecret: @consumerSecret
      twitterUri: 'http://api.example.org'

    @request = sinon.stub()
    @httpServer = sinon.createStubInstance http.Server
    sinon.restore @httpServer.listen
    sinon.restore @httpServer.on
    sinon.restore @httpServer.emit
    sinon.stub @httpServer, 'listen', =>
      @httpServer.emit 'listening'
    @http =
      createServer: sinon.stub().returns @httpServer
    @logger = sinon.createStubInstance Logger

    @server = new Server @options, @request, @http, @logger

    @obtainTokenOptions =
        uri: 'http://api.example.org/oauth2/token'
        method: 'POST'
        headers:
          authorization: 'Basic eHZ6MWV2RlM0d0VFUFRHRUZQSEJvZzpMOHFxOVBaeVJnNmllS0dFS2hab2xHQzB2SldMdzhpRUo4OERSZHlPZw=='
        form:
          grant_type: 'client_credentials'

  suite '#constructor()', =>

    test 'members', =>
      assert.strictEqual @server._options, @options
      assert.strictEqual @server._request, @request
      assert.strictEqual @server._http, @http
      assert.strictEqual @server._logger, @logger

    test 'member defaults', =>
      @options =
        consumerKey: 'xvz1evFS4wEEPTGEFPHBog'
        consumerSecret: 'L8qq9PZyRg6ieKGEKhZolGC0vJWLw8iEJ88DRdyOg'
      @server = new Server @options

      assert.strictEqual @server._options.twitterUri, 'https://api.twitter.com'
      assert.strictEqual @server._request, request
      assert.strictEqual @server._http, http
      assert.instanceOf @server._logger, Logger

    test 'requires consumer key', =>
      expect(=> new Server consumerSecret: 'L8qq9PZyRg6ieKGEKhZolGC0vJWLw8iEJ88DRdyOg').to.throw 'Consumer key is required.'

    test 'requires consumer secret', =>
      expect(=> new Server consumerKey: 'xvz1evFS4wEEPTGEFPHBog').to.throw 'Consumer secret is required.'

  suite '#listen()', =>

    test 'obtains a token before handling requests', (done) =>
      response =
        statusCode: 200
      responseBody = '{"token_type":"bearer","access_token":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}'
      @request.callsArgOnWith 1, @server, null, response, responseBody

      @server.listen 111, (error) =>
        assert.isNull error
        sinon.assert.calledOnce @request
        sinon.assert.calledOn @request, @server
        sinon.assert.calledWithExactly @request, @obtainTokenOptions, sinon.match.func
        sinon.assert.calledOnce @http.createServer
        sinon.assert.calledWithExactly @http.createServer, sinon.match.func
        sinon.assert.calledOnce @httpServer.listen
        sinon.assert.calledWithExactly @httpServer.listen, 111
        sinon.assert.callOrder \
          @logger.log.withArgs('info', 'Obtaining bearer token.'),
          @request,
          @logger.log.withArgs('info', 'Successfully obtained bearer token.'),
          @http.createServer,
          @logger.log.withArgs('info', 'Listening on port %d.', 111)
        done()

    test 'port defaults to 8000', (done) =>
      response =
        statusCode: 200
      responseBody = '{"token_type":"bearer","access_token":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}'
      @request.callsArgOnWith 1, @server, null, response, responseBody

      @server.listen null, (error) =>
        assert.isNull error
        sinon.assert.calledOnce @request
        sinon.assert.calledOn @request, @server
        sinon.assert.calledWithExactly @request, @obtainTokenOptions, sinon.match.func
        sinon.assert.calledOnce @http.createServer
        sinon.assert.calledWithExactly @http.createServer, sinon.match.func
        sinon.assert.calledOnce @httpServer.listen
        sinon.assert.calledWithExactly @httpServer.listen, 8000
        sinon.assert.callOrder \
          @logger.log.withArgs('info', 'Obtaining bearer token.'),
          @request,
          @logger.log.withArgs('info', 'Successfully obtained bearer token.'),
          @http.createServer,
          @logger.log.withArgs('info', 'Listening on port %d.', 8000)
        done()

    test 'returns an error when obtaining a token results in an HTTP error', (done) =>
      response =
        statusCode: 500
      responseBody = 'Internal server error.'
      @request.callsArgOnWith 1, @server, null, response, responseBody

      @server.listen 111, (error) =>
        assert.strictEqual response, error
        sinon.assert.calledOnce @request
        sinon.assert.calledOn @request, @server
        sinon.assert.calledWithExactly @request, @obtainTokenOptions, sinon.match.func
        sinon.assert.notCalled @http.createServer
        sinon.assert.callOrder \
          @logger.log.withArgs('info', 'Obtaining bearer token.'),
          @request,
          @logger.error.withArgs('Unable to obtain bearer token. Unexpected HTTP error (%s).', 500)
        done()

    test 'returns an error when obtaining a token results in an error', (done) =>
      @request.callsArgOnWith 1, @server, 'error', null, null

      @server.listen 111, (error) =>
        assert.strictEqual error, 'error'
        sinon.assert.calledOnce @request
        sinon.assert.calledOn @request, @server
        sinon.assert.calledWithExactly @request, @obtainTokenOptions, sinon.match.func
        sinon.assert.notCalled @http.createServer
        sinon.assert.callOrder \
          @logger.log.withArgs('info', 'Obtaining bearer token.'),
          @request,
          @logger.error.withArgs('Unable to obtain bearer token. Unexpected error.')
        done()

  suite 'functional tests', =>

    setup (done) =>
      @request = sinon.spy request
      @http = http
      sinon.spy @http, 'createServer'

      portfinder.getPort (error, port) =>
        return done error if error

        @httpPort = port

        @httpServer = http.createServer (request, response) =>
          if request.url is '/oauth2/token'
            response.writeHead 200, 'content-type': 'application/json'
            response.end '{"token_type":"bearer","access_token":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}'
          else
            response.writeHead 200, 'content-type': 'text/plain'
            response.end 'Mooch!'

        @httpServer.on 'listening', =>
          portfinder.getPort (error, port) =>
            return done error if error

            @port = port
            @options =
              consumerKey: @consumerKey
              consumerSecret: @consumerSecret
              twitterUri: util.format 'http://localhost:%d', @httpPort
              allow: [/^\/path\/to/]
              deny: [/bar/]

            @server = new Server @options, @request, @http, @logger
            @server.listen @port, done

        @httpServer.listen port

    teardown =>
      sinon.restore @http, 'createServer'

    test 'correctly proxies requests', (done) =>
      options =
        uri: util.format 'http://localhost:%d/path/to/foo', @port
        method: 'POST'
        headers:
          'x-custom-header': 'header-value'
        form:
          post_var: 'post-value'

      expectedOptions =
          uri: util.format 'http://localhost:%d/path/to/foo', @httpPort
          method: 'POST'
          headers:
            'x-custom-header': 'header-value'
            'content-type': 'application/x-www-form-urlencoded; charset=utf-8'
            'content-length': '19'
            'connection': 'keep-alive'
            'authorization': 'Bearer AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
          body: 'post_var=post-value'
          followRedirect: false

      request options, (error, response, body) =>
        assert.isNull error
        sinon.assert.calledWith @request, expectedOptions
        sinon.assert.calledWith @logger.log, 'request', '%s "%s %s HTTP/%s" %s %s', '127.0.0.1', 'POST', '/path/to/foo', '1.1', 200, 6
        assert.strictEqual body, 'Mooch!'
        done()

    test 'does not clobber existing authorization header', (done) =>
      options =
        uri: util.format 'http://localhost:%d/path/to/foo', @port
        method: 'POST'
        headers:
          'x-custom-header': 'header-value'
          'authorization': 'auth-value'
        form:
          post_var: 'post-value'

      expectedOptions =
          uri: util.format 'http://localhost:%d/path/to/foo', @httpPort
          method: 'POST'
          headers:
            'x-custom-header': 'header-value'
            'content-type': 'application/x-www-form-urlencoded; charset=utf-8'
            'content-length': '19'
            'connection': 'keep-alive'
            'authorization': 'auth-value'
          body: 'post_var=post-value'
          followRedirect: false

      request options, (error, response, body) =>
        assert.isNull error
        sinon.assert.calledWith @request, expectedOptions
        sinon.assert.calledWith @logger.log, 'request', '%s "%s %s HTTP/%s" %s %s', '127.0.0.1', 'POST', '/path/to/foo', '1.1', 200, 6
        assert.strictEqual body, 'Mooch!'
        done()

    test 'only allows paths matching the allow rules', (done) =>
      options =
        uri: util.format 'http://localhost:%d/foo', @port

      request options, (error, response, body) =>
        assert.isNull error
        sinon.assert.calledWith @logger.log, 'request', '%s "%s %s HTTP/%s" 403 -', '127.0.0.1', 'GET', '/foo', '1.1'
        assert.strictEqual body, '{"errors":[{"message":"Forbidden.","code":64}]}'
        done()

    test 'does not allow paths matching the deny rules', (done) =>
      options =
        uri: util.format 'http://localhost:%d/path/to/%62%61%72', @port

      request options, (error, response, body) =>
        assert.isNull error
        sinon.assert.calledWith @logger.log, 'request', '%s "%s %s HTTP/%s" 403 -', '127.0.0.1', 'GET', '/path/to/%62%61%72', '1.1'
        assert.strictEqual body, '{"errors":[{"message":"Forbidden.","code":64}]}'
        done()
