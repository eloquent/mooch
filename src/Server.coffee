###
This file is part of the Mooch package.

Copyright © 2013 Erin Millard

For the full copyright and license information, please view the LICENSE
file that was distributed with this source code.
###

util = require 'util'

module.exports = class Server

  constructor: (options, request = (require 'request'), http = (require 'http'), output = process.stdout) ->
    throw 'Consumer key is required.' if not options.consumerKey
    throw 'Consumer secret is required.' if not options.consumerSecret
    options.port = 8000 if not options.port
    options.twitterUri = 'https://api.twitter.com' if not options.twitterUri

    @_options = options
    @_request = request
    @_http = http
    @_output = output

  start: (callback) ->
    @_obtainToken (error, token) =>
      if error
        @_output.write 'Unable to obtain bearer token, shutting down.'
        return callback error
      @_token = token
      @_handle callback

  _obtainToken: (callback) ->
    options =
      uri: @_options.twitterUri + '/oauth2/token'
      method: 'POST'
      headers:
        authorization: util.format 'Basic %s', @_generateRequestToken()
      form:
        grant_type: 'client_credentials'

    @_output.write 'Obtaining bearer token... '
    @_request options, (error, response, body) =>
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

  _handle: (callback) ->
    server = @_http.createServer (request, response) =>
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

        @_request(options).pipe response

    server.listen @_options.port
    @_output.write util.format 'Mooch listening on localhost:%d.\n', @_options.port
    callback null

  _generateRequestToken: ->
    encodedConsumerKey = encodeURIComponent @_options.consumerKey
    encodedConsumerSecret = encodeURIComponent @_options.consumerSecret
    encodedRequestPair = util.format '%s:%s', encodedConsumerKey, encodedConsumerSecret
    new Buffer(encodedRequestPair).toString 'base64'
