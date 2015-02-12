
# Foursquare collector module

This module is responsible for collection of user data from Foursquare.

    debug       = (require 'debug') 'memdive::collectors::foursquare'
    async       = require 'async'
    Foursquare  = require '4sq'
    _           = require 'lodash'

## Initialization

During initialization we perform the standard operations for all the collectors: we capture the CompoundJS app context, add this module to its set of collectors and signal the rest of the app that the collector is ready.

    app = undefined

    exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.collectors = app.collectors or {}
            app.collectors.foursquare = exports
            app.emit 'foursquareCollectorReady'

## Exported functions

### `collectCheckins`

This function will collect provider's associated Foursquare checkin data. It accepts three parameters:

1. `provider`: the user data provider object for which the data is being collected
2. `params`: optional params parameter with additional flags and options (`suppressThrottling` is the only one used)
3. `callback`: the callback function of `(err, item, next)` signature through which the method passes errors and items to the client. `next` is a function interator and should be invoked by the client when it has finished processing of the item (though not of error - in that case iteration shouldn't continue).

    collectCheckIns = (provider, params, callback) ->

Since params is optional, it may be omitted by the clients in which case in its place we will have the callback function.

        if typeof params == 'function'
            callback = params
            params = {}

        return app.common.hellRaiser.invalidArgs arguments, callback if not provider or not params or not callback

Ensure that we have enough data to attempt collection of the data. In this case we have no option but to throw.

        throw new Error('Invalid input params') if not provider or not params or not callback

        if provider.providerId isnt app.common.constants.providerId.FOURSQUARE or not provider.providerData or not provider.providerData.token
            return process.nextTick () ->
                return callback new Error('Provider not validly associated with Foursquare')

        foursquare = new Foursquare {
            token: provider.providerData.token
            date:  20140612 # This is needed to stabilize Foursquare API version which changes by the day
        }
        currentOffset = 0

        readData = () ->
            foursquare.checkins 'self', { limit: 100, offset: currentOffset }, (err, response) ->
                return callback err if err or not response
                return callback null if _.isEmpty response?.checkins?.items

We asynchronously but serially iterate over all the items in the reply. The client invoked through callback is required to invoke next() for the next iteration to kick in.

                async.eachSeries response.checkins.items, (checkin, next) ->
                    return callback null, checkin, next
                , (err) ->
                    return callback err if err
                    currentOffset += response.checkins.items.length
                    readData()

        return readData()

    exports.collectCheckIns = collectCheckIns
