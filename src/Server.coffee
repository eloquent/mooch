http = require 'http'
executeRequest = require 'request'
util = require 'util'

module.exports = class Server

  constructor: (options, output = process.stdout) ->
    @_options = options
    @_output = output

    @_options.port = 80 if not @_options.port
    @_options.twitterUri = 'https://api.twitter.com' if not @_options.twitterUri

  start: ->
    @_obtainToken (error, token) =>
      if error
        return @_output.write 'Unable to obtain bearer token, shutting down.'
      @_token = token
      @_handle()

  _obtainToken: (callback) ->
    options =
      uri: @_options.twitterUri + '/oauth2/token'
      method: 'POST'
      headers:
        authorization: util.format 'Basic %s', @_generateRequestToken()
      form:
        grant_type: 'client_credentials'

    @_output.write 'Obtaining bearer token... '
    executeRequest options, (error, response, body) =>
      if error
        @_output.write 'unknown error.\n'
        callback error
      else
        if response.statusCode is 200
          responseVariables = JSON.parse body
          @_output.write 'done.\n'
          callback null, responseVariables.access_token
        else
          @_output.write util.format 'HTTP error (%s).\n', response.statusCode
          callback response

  _handle: ->
    server = http.createServer (request, response) =>
      requestBody = ''
      request.on 'readable', ->
        requestBody += request.read()
      request.on 'end', =>
        options =
          uri: @_options.twitterUri + request.url
          method: request.method
          headers: request.headers
          body: requestBody
          followRedirect: false
        delete options.headers[property] for property of options.headers when property.toLowerCase() is 'host'
        options.headers.authorization = util.format 'Bearer %s', @_token

        executeRequest(options).pipe response

    server.listen @_options.port
    @_output.write util.format 'Mooch listening on localhost:%d.\n', @_options.port

  _generateRequestToken: ->
    encodedConsumerKey = encodeURIComponent @_options.consumerKey
    encodedConsumerSecret = encodeURIComponent @_options.consumerSecret
    encodedRequestPair = util.format '%s:%s', encodedConsumerKey, encodedConsumerSecret
    new Buffer(encodedRequestPair).toString 'base64'
