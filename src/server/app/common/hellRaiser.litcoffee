
# hellRaiser module

This module is repsonsible for uniform raising of errors throughtout the system.

    _ = require 'lodash'

## Initialization

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::common::hellRaiser'

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.hellRaiser = exports
            app.emit 'hellRaiserReady'

## Public functions

### `raise`

`raise` will create a new `Error` object with the given `message` and optional `code`. In case that `callback` hasn't been provided the new object will be thrown, otherwise it will be passed as the first parameter to `callback` function which will be invoked asynchronously on nextTick().

    raise = (message, code, callback) ->
        error = new Error(message)
        error.code = code

        if callback and _.isFunction callback
            return process.nextTick ->
                return callback error

        throw error

    exports.raise = raise

### `userNotFound`

    userNotFound = (userId, callback) ->
        raise 'User ' + userId + ' not found', app.common.constants.error.USER_NOT_FOUND, callback

    exports.userNotFound = userNotFound

### `invalidArgs`

    invalidArgs = (args, callback) ->
        if not _.isArray(args) or _.isEmpty(args)
            message = 'no arguments'
        else
            message = args.join(', ')

        raise message, app.common.constants.error.INVALID_ARGS, callback

    exports.invalidArgs = invalidArgs
