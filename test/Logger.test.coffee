###
This file is part of the Mooch package.

Copyright © 2014 Erin Millard

For the full copyright and license information, please view the LICENSE file
that was distributed with this source code.
###

{assert} = require 'chai'
moment = require 'moment'
sinon = require 'sinon'
Logger = require '../' + process.env.TEST_ROOT + '/Logger'

suite 'Logger', =>

  setup =>
    @moment = sinon.stub().returns @moment
    @moment.format = sinon.stub().returns '2013-07-04T14:38:57+10:00'
    @output =
      log: sinon.stub(),
      error: sinon.stub()
    @logger = new Logger @moment, @output

  suite '#constructor()', =>

    test 'members', =>
      assert.strictEqual @logger._moment, @moment
      assert.strictEqual @logger._output, @output

    test 'member defaults', =>
      @logger = new Logger

      assert.strictEqual @logger._moment, moment
      assert.strictEqual @logger._output, console

  suite '#log()', =>

    test 'logs to console.log', =>
      @logger.log 'category', 'Message %s with %s wildcards.', 'foo', 'bar'
      sinon.assert.calledWithExactly \
        @output.log,
        '[%s] [%s] %s',
        '2013-07-04T14:38:57+10:00',
        'category',
        'Message foo with bar wildcards.'

  suite '#error()', =>

    test 'logs to console.error', =>
      @logger.error 'Message %s with %s wildcards.', 'foo', 'bar'
      sinon.assert.calledWithExactly \
        @output.error,
        '[%s] [error] %s',
        '2013-07-04T14:38:57+10:00',
        'Message foo with bar wildcards.'
