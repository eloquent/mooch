###
This file is part of the Mooch package.

Copyright © 2013 Erin Millard

For the full copyright and license information, please view the LICENSE
file that was distributed with this source code.
###

querystring = require 'querystring'
url = require 'url'
util = require 'util'
Logger = require './Logger'

module.exports = class Server

  constructor: ( \
    options,
    request = (require 'request'),
    http = (require 'http'),
    logger = new Logger
  ) ->
    throw new Error 'Consumer key is required.' if not options.consumerKey
    throw new Error 'Consumer secret is required.' if not options.consumerSecret
    options.twitterUri = 'https://api.twitter.com' if not options.twitterUri
    options.allow = [] if not options.allow
    options.deny = [] if not options.deny

    @_options = options
    @_request = request
    @_http = http
    @_logger = logger

  listen: (port = 8000, callback) ->
    @_obtainToken (error, token) =>
      if error
        @_logger.error 'Unable to obtain bearer token, shutting down.'
        callback error if callback
        return
      @_token = token
      @_handle port, callback

  _obtainToken: (callback) ->
    options =
      uri: @_options.twitterUri + '/oauth2/token'
      method: 'POST'
      headers:
        authorization: util.format 'Basic %s', @_generateRequestToken()
      form:
        grant_type: 'client_credentials'

    @_logger.log 'info', 'Obtaining bearer token.'
    @_request options, (error, response, body) =>
      if error
        @_logger.error 'Unable to obtain bearer token. Unexpected error.'
        callback error if callback
      else
        if response.statusCode is 200
          responseVariables = JSON.parse body
          @_logger.log 'info', 'Successfully obtained bearer token.'
          callback null, responseVariables.access_token if callback
        else
          @_logger.error 'Unable to obtain bearer token. Unexpected HTTP error (%s).', response.statusCode
          callback response if callback

  _handle: (port, callback) ->
    @_server = @_http.createServer (request, response) =>
      if !@_requestAllowed request
        response.writeHead 403, 'content-type': 'application/json'
        response.end '{"errors":[{"message":"Forbidden.","code":64}]}'
        @_logger.log 'info', 'Client denied by configuration rules.'
        @_logger.log \
          'request',
          '%s "%s %s HTTP/%s" 403 -',
          request.connection.remoteAddress,
          request.method,
          request.url,
          request.httpVersion
        return
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

        contentLength = 0
        innerRequest = @_request options
        innerRequest.on 'data', (chunk) =>
          contentLength += chunk.length
        innerRequest.on 'end', =>
          @_logger.log \
            'request',
            '%s "%s %s HTTP/%s" %s %s',
            request.connection.remoteAddress,
            request.method,
            request.url,
            request.httpVersion,
            response.statusCode,
            contentLength or '-'
        innerRequest.pipe response

    @_server.on 'listening', =>
      @_logger.log 'info', 'Listening on port %d.', port
      callback null if callback
    @_server.listen port

  _generateRequestToken: ->
    encodedConsumerKey = encodeURIComponent @_options.consumerKey
    encodedConsumerSecret = encodeURIComponent @_options.consumerSecret
    encodedRequestPair = util.format '%s:%s', encodedConsumerKey, encodedConsumerSecret
    new Buffer(encodedRequestPair).toString 'base64'

  _requestAllowed: (request) ->
    uriParts = url.parse request.url
    normalizedUri = url.format
      pathname: decodeURIComponent uriParts.pathname
      search: querystring.stringify querystring.parse uriParts.query
    allowMatched = @_options.allow.length < 1
    for pattern in @_options.allow
      if normalizedUri.match pattern
        allowMatched = true
        break
    return false if !allowMatched
    return false for pattern in @_options.deny when normalizedUri.match pattern
    return true
