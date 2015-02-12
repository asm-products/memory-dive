
# slackWorker module

This module is responsible for configuring and invoking `genericWorker` in order to collect and persist data from Slack.

## Initialization

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::workers::slack'

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.workers = app.workers or {}
            app.workers.slack = exports
            app.emit 'slackWorkerReady'

## Private functions

Slack stores its timestamps as the number of seconds since Unix epoch and behind-the-floating-point message counter.

    convertToUnixEpoch = (slackTime) ->
        return 1000 * Math.floor slackTime

## Public functions

To allow the rest of the system to actually use this module we export a single method: `updateMessages`.
This method is responsible for coordinating different processes that have to be performed.

This method accepts three parameters:

1. `scheduler`: the scheduler object if the invocation of this method is being done through a scheduler; otherwise `undefined`
2. `provider`: a `UserProviderData` object for which we are collecting the data. This parameter cannot be `undefined` or otherwise falsy.
3. `callback`: the callback function of `(err, result)` signature to be invoked once the processing finishes. `result` is an object that, if present, will contain `count` with the number of collected objects.

--

    updateMessages = (scheduler, provider, callback) ->

        debug 'updateMessages'

We ensure that the callback function exists one way or the other.

        callback = callback || (err) ->
            console.log err if err

We ensure that the input parameters are correct.

        return app.common.hellRaiser.invalidArgs arguments, callback if not provider or provider.providerId isnt app.common.constants.providerId.SLACK

        app.workers.generic.updateUserData {
            scheduler:  scheduler
            provider:   provider
            collector:  app.collectors.slack.collectMessages

We skip non-messages and messages from other users except when they were starred by our user.

            filter:     (item) ->
                return item and item.message and item.message.type is 'message' and (item.message.user is provider.providerData.userId or item.message.is_starred)

Normalize the data before sending it to SlackObject creator.

            generator:  (item) ->
                message = item.message
                channel = item.channel
                data =
                    # Slack doesn't have a distinctive modelId per message
                    # and instead hacks the `ts` (timestamp) value to provider one.
                    modelId:    channel.name + '-' + message.ts
                    channel:    channel.name
                    type:       message.type
                    text:       message.text
                    extra:
                        subtype:    message.subtype
                    utcOffset:  item.utcOffset
                    timestamp:  convertToUnixEpoch message.ts

                return app.models.SlackObject.createObject provider, data

            callback: callback
        }

    exports.updateMessages = updateMessages
