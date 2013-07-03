###
This file is part of the Mooch package.

Copyright © 2013 Erin Millard

For the full copyright and license information, please view the LICENSE
file that was distributed with this source code.
###

util = require 'util'

module.exports = class Server

  constructor: (options, request = (require 'request'), http = (require 'http'), output = process.stdout) ->
    throw new Error 'Consumer key is required.' if not options.consumerKey
    throw new Error 'Consumer secret is required.' if not options.consumerSecret
    options.twitterUri = 'https://api.twitter.com' if not options.twitterUri

    @_options = options
    @_request = request
    @_http = http
    @_output = output

  listen: (port = 8000, callback) ->
    @_obtainToken (error, token) =>
      if error
        @_output.write 'Unable to obtain bearer token, shutting down Mooch server.\n'
        callback error if callback
        return
      @_token = token
      @_handle port, callback

  close: (callback) ->
    if @_server
      @_output.write 'Shutting down Mooch server... '
      @_server.close (error) =>
        if error
          @_output.write 'failed.\n'
          callback error if callback
          return
        delete @_server
        @_output.write 'done.\n'
        callback null if callback

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
        callback error if callback
      else
        if response.statusCode is 200
          responseVariables = JSON.parse body
          @_output.write 'done.\n'
          callback null, responseVariables.access_token if callback
        else
          @_output.write util.format 'HTTP error (%s).\n', response.statusCode
          callback response if callback

  _handle: (port, callback) ->
    @_server = @_http.createServer (request, response) =>
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
        options.headers.authorization = util.format 'Bearer %s', @_token if !options.headers.authorization?

        @_request(options).pipe response

    @_server.on 'listening', =>
      @_output.write util.format 'Mooch listening on port %d.\n', port
      callback null if callback
    @_server.listen port

  _generateRequestToken: ->
    encodedConsumerKey = encodeURIComponent @_options.consumerKey
    encodedConsumerSecret = encodeURIComponent @_options.consumerSecret
    encodedRequestPair = util.format '%s:%s', encodedConsumerKey, encodedConsumerSecret
    new Buffer(encodedRequestPair).toString 'base64'
