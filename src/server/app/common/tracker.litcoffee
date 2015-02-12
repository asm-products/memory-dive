
# Tracker module

This module is responsible for tracking user actions both on server and client (through REST API). It abstracts the rest of the system from the concrete analytics platform that Memory Dive uses.

## Required modules

    _           = require 'lodash'
    debug       = (require 'debug') 'memdive::common::tracker'
    Analytics   = require('analytics-node')

## MemoryDive modules

    eventModel = undefined

## Module variables

    app = undefined
    segmentIo = undefined
    testEnvironment = process.env.NODE_ENV == 'test'

## Initialization

The module is integrated into CompoundJS application.

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.tracker = exports
            app.emit 'trackerReady'

            compound.on 'memoryDiveReady', ->
                eventModel = compound.models.Event

                # When running in test environment we don't create segment.io module
                # but place a mock object instead of it. This then doesn't mess up our HTTP
                # nocking neither with segment.io timestamps nor with indeterministic HTTP requests.
                if not testEnvironment
                    segmentIo = new Analytics(compound.common.config.SEGMENT_IO_WRITE_KEY)
                else
                    segmentIo =
                        identify:   () -> {}
                        track:      () -> {}

## Private functions

    save = (event, optionalCallback) ->
        console.log 'count#' + event.type + '=1'

        event.save (err, savedEvent) ->
            debug 'Error while saving event', event.userId, event.type, err if err
            optionalCallback(err, savedEvent) if optionalCallback

        segmentIo.track {
            userId: event.userId
            event:  event.type
        }, (err) ->
            debug 'Failed to track at segment.io:', err if err

## Exported functions

Our general implementation pattern for all exported function is:

1. Immediately create `Event` model object.
2. Initiate the logging of the event to our database and eventually invoke the optional callback with results of that operation.
3. Initiate the logging of the event to segment.io ignoring the errors (just logging them to `debug`)

We care about segment.io errors and we will log them them in debug output *but* they don't entirely depend on us and missing them is far less relevant than handling our own errors (if the optional callback is even defined).

    userSignedUp = (user, optionalCallback) ->
        debug 'User', user.id, 'signed up'
        event = eventModel.createObject user.id, eventModel.type.USER_SIGNED_UP
        save event, optionalCallback

    exports.userSignedUp = userSignedUp

### `userSignedIn`

This function logs the signed-in event and identifies the user in front of segment.io. Upon signing in we (re)identify our user in segment.io. As this is analytics we don't particually care if it succeeds or not so we don't wait for that to finish in order for logging to our database to proceeed. But we do invoke `save` after having initiated the identification as segment.io module has batching and we want that operation to be batched before the tracking operation.

    userSignedIn = (user, optionalCallback) ->
        debug 'User', user.id, 'signed in'

        event = eventModel.createObject user.id, eventModel.type.USER_SIGNED_IN

        segmentIo.identify {
            userId: user.id
            traits:
                name:       user.displayName
                email:      user.email
                createdAt:  user.createdOn
        }, (segmentIoErr) ->
            debug 'Failed to identify at segment.io:', segmentIoErr if segmentIoErr

        save event, optionalCallback

    exports.userSignedIn = userSignedIn

    userSignedOut = (user, optionalCallback) ->
        debug 'User', user.id, 'signed out'
        event = eventModel.createObject user.id, eventModel.type.USER_SIGNED_OUT
        save event, optionalCallback

    exports.userSignedOut = userSignedOut
