###
This file is part of the Mooch package.

Copyright © 2013 Erin Millard

For the full copyright and license information, please view the LICENSE
file that was distributed with this source code.
###

util = require 'util'

module.exports = class Logger

  constructor: (moment = (require 'moment'), output = console) ->
    @_moment = moment
    @_output = output

  log: (category, message, messageArguments...) ->
    @_output.log '[%s] [%s] %s', @_moment().format(), category, util.format(message, messageArguments...)

  error: (message, messageArguments...) ->
    @_output.error '[%s] [error] %s', @_moment().format(), util.format(message, messageArguments...)
