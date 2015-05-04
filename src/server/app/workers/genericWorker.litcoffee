
# genericWorker module

This module is responsible for:

1. Invoking collection through a data collector.
2. Receiving the collected data and passing it into a document generator.
3. Requesting the persistence of the generated documents.

## Initialization

    debug   = (require 'debug') 'memdive::workers::generic'
    _       = require 'lodash'

During the initialization of the module we perform several duties:

1. Capturing of the CompoundJS's app context so we can later access modules and collectors.
2. Registering the worker with the same app context so that other parts of the app can use us.
3. Signaling the rest of the app that this module is ready so that the app can proceed.

    app = undefined

    exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.workers = app.workers or {}
            app.workers.generic = exports
            app.emit 'genericWorkerReady'

## Constants

## Public functions

### `updateUserData`

This method accepts a single object parameter with the following properties:

1. `scheduler`: the scheduler object if the invocation of this method is being done through a scheduler; otherwise `undefined`
2. `provider`: a `UserProviderData` object for which we are collecting the data. This parameter cannot be `undefined` or otherwise falsy.
3. `collector`: a function of `(provider, callback)` signature that collects the data.
4. `filter`: a function accepting collected data items, one by one, and returning a truthy or falsy value depending on whether the data should be persisted.
5. `generator`: a function accepting collected data and returning a document object to be persisted.
6. `callback`: the callback function of `(err, result)` signature to be invoked once the processing finishes. `result` is an object that, if present, will contain `count` with the number of collected objects.

--

    updateUserData = (params) ->

        scheduler = params.scheduler
        provider = params.provider
        collector = params.collector
        filter = params.filter
        generator = params.generator
        # `callback` is optional
        callback = params.callback || (err) ->
            console.error err if err

        debug 'updateUserData'

We ensure that the input parameters are correct.

        return app.common.hellRaiser.invalidArgs arguments, callback unless provider and collector and generator

Get the user object from the database as we need its timezone offset.

        app.models.User.find provider.userId, (err, user) ->
            return callback err if err
            return app.common.hellRaiser.userNotFound provider.userId, callback if not user

All collected items will be assigned user's current UTC offset.

            utcOffset = user.getUtcOffset()

We start collecting the data iteratively.

            collector provider, (err, item, next) ->
                return callback err if err

Once the collection has finished (item is falsy) we issue the callback.

                return callback() unless item

For each retrieved status we create a new object that will be persisted to the database. Note that creator function may return `undefined` for items that cannot be meaningfully used.

Before we create the object we add it the `utcOffset` we got from the user.

                item.utcOffset = utcOffset

Filter the items to be created, if `filter` was passed.

                return next() if filter and not filter(item)

Generate the object and enqueue it for uploading.

                object = generator item
                if not _.isUndefined object
                    app.common.bulkDataUploader.enqueue object

Prevent too deep recursion by invoking `next` in the next event loop.

                setImmediate () ->
                    return next()
                , 0

    exports.updateUserData = updateUserData
