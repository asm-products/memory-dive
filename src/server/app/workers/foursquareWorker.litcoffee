
# foursquareWorker module

This module is responsible for configuring and invoking `genericWorker` in order to collect and persist data from Foursquare.

## Initialization

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::workers::foursquare'

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.workers = app.workers or {}
            app.workers.foursquare = exports
            app.emit 'foursquareWorkerReady'

## Private functions

Foursquare servers time datums in seconds.

    SECONDS_TO_MILLISECONDS = 1000

    foursquareTimeToUnixEpoch = (time) ->
        return SECONDS_TO_MILLISECONDS * time

## Public functions

To allow the rest of the system to actually use this module we export a single method: `updateCheckIns`.
This method is responsible for coordinating different processes that have to be performed.

This method accepts three parameters:

1. `scheduler`: the scheduler object if the invocation of this method is being done through a scheduler; otherwise `undefined`
2. `provider`: a `UserProviderData` object for which we are collecting the data. This parameter cannot be `undefined` or otherwise falsy.
3. `callback`: the callback function of `(err, result)` signature to be invoked once the processing finishes. `result` is an object that, if present, will contain `count` with the number of collected objects.

--

    updateCheckIns = (scheduler, provider, callback) ->

        debug 'updateCheckIns'

We ensure that the callback function exists one way or the other.

        callback = callback || (err) ->
            console.log err if err

We ensure that the input parameters are correct.

        return app.common.hellRaiser.invalidArgs arguments, callback if not provider or provider.providerId isnt app.common.constants.providerId.FOURSQUARE

        app.workers.generic.updateUserData {
            scheduler:  scheduler
            provider:   provider
            collector:  app.collectors.foursquare.collectCheckIns
            filter:     undefined

Normalize the data before sending it to FoursquareObject creator.

            generator:  (item) ->
                data =
                    modelId:    item.id
                    type:       item.type
                    text:       item.shout
                    extra:
                        timeZoneOffset: item.timeZoneOffset
                        venue:
                            id:         item.venue?.id
                            name:       item.venue?.name
                            location:   item.venue?.location
                    utcOffset:  item.utcOffset
                    createdAt:  foursquareTimeToUnixEpoch item.createdAt

                return app.models.FoursquareObject.createObject provider, data

            callback: callback
        }

    exports.updateCheckIns = updateCheckIns
