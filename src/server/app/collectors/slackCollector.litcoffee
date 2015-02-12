
# Slack collector module

This module is responsible for collection of user data from Slack.

    debug       = (require 'debug') 'memdive::collectors::slack'
    async       = require 'async'
    Slack       = (require 'slack-node')
    _           = require 'lodash'

## Initialization

During initialization we perform the standard operations for all the collectors: we capture the CompoundJS app context, add this module to its set of collectors and signal the rest of the app that the collector is ready.

    app = undefined

    exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.collectors = app.collectors or {}
            app.collectors.slack = exports
            app.emit 'slackCollectorReady'

## Exported functions

### `collectMessages`

This function will collect provider's associated Slack messages data. It accepts three parameters:

1. `provider`: the user data provider object for which the data is being collected
2. `params`: optional params parameter with additional flags and options (`suppressThrottling` is the only one used)
3. `callback`: the callback function of (err, item, next) signature through which the method passes errors and items to the client. `next` is a function interator and should be invoked by the client when it has finished processing of the item (though not of error - in that case iteration shouldn't continue).

    collectMessages = (provider, params, callback) ->

Since params is optional, it may be omitted by the clients in which case in its place we will have the callback function.

        if typeof params == 'function'
            callback = params
            params = {}

        return app.common.hellRaiser.invalidArgs arguments, callback if not provider or not params or not callback

Ensure that we have enough data to attempt collection of the data. In this case we have no option but to throw.

        throw new Error('Invalid input params') if not provider or not params or not callback

        if provider.providerId isnt app.common.constants.providerId.SLACK or not provider.providerData or not provider.providerData.token
            return process.nextTick () ->
                return callback new Error('Provider not validly associated with Slack')

        slack = new Slack provider.providerData.token

        slack.api 'channels.list', (err, response) ->
            return callback err if err or not response

            return callback new Error 'Slack error on channels.list: ' + response.error if not response.ok or response.error

In order to liberate the process to do other things while waiting on the collection of Slack channels, we keep the list of pending channels and iterate over it, collecting each channel separately.

            pendingChannels = response.channels

            readNextChannel = () ->

                return callback() if _.isEmpty(pendingChannels)

                channel = pendingChannels.pop()

                debug ' > Collecting channel', channel.name, channel.id

                currentOldest = 0

                readNextMessagesBatch = () ->
                    debug ' >> Reading messages starting from', currentOldest

                    slack.api 'channels.history', {
                            channel: channel.id
                            oldest: currentOldest
                    }, (error, result) ->
                        return callback error if error
                        return callback new Error 'Slack error on channels.history: ' + response.error if not response.ok or response.error

We asynchronously but serially iterate over all the items in the reply. The client invoked through callback is required to invoke next() for the next iteration to kick in.

                        async.eachSeries result.messages, (message, next) ->
                            currentOldest = message.ts

                            return callback null, {
                                channel: channel,
                                message: message
                            }, next
                        , (err) ->
                            return callback err if err
                            return readNextChannel() if _.isEmpty response.messages
                            readNextMessagesBatch()

We start the reading of notes by reading the next (first) batch of notes.

                readNextMessagesBatch()

We start the reading of notebooks by reading the next (first) notebook.

            readNextChannel()

    exports.collectMessages = collectMessages
