
# backupAdminWorker module

This module is responsible for:

1. Collection of all user data (documents that have the same matching `userId`)
2. Processing of collected data.
2. Requesting the persistence of collected data on the backup provider.

## Initialization

    debug   = (require 'debug') 'memdive::workers::backupAdmin'
    _       = require 'lodash'

During the initialization of the module we perform several duties:

1. Capturing of the CompoundJS's app context so we can later access modules and collectors.
2. Registering the worker with the same app context so that other parts of the app can use us.
3. Signaling the rest of the app that this module is ready so that the app can proceed.

--

    app = undefined

    exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.workers = app.workers or {}
            app.workers.backupAdmin = exports
            app.emit 'backupAdminWorkerReady'

## Constants

    ALL_USER_DATA_DOC = 'allUserData'
    VIEW = 'view'

## Exported functions

### `backupUserDataAsJson`

This method accepts three parameters:

1. `scheduler`: the scheduler object if the invocation of this method is being done through a scheduler; otherwise `undefined`
2. `provider`: a UserBackupProvider object to which we will persist the data to backup. This parameter cannot be `undefined` or otherwise falsy.
3. `callback`: the callback function to be invoked with err parameter in the case of error or no parameters once the process finishes.

--

    backupUserDataAsJson = (scheduler, provider, callback) ->

        # `callback` is optional
        callback = callback or (err) ->
            console.error err if err
        persistor = app.common.objectFactory.producePersistor provider?.providerId

        debug 'backupUserDataAsJson'

We ensure that the input parameters are correct.

        return app.common.hellRaiser.invalidArgs(arguments, callback) unless scheduler and provider and persistor

We collect the

        viewParams =
            key:            provider.userId
            skip:           0
            limit:          10000
            reduce:         false
            include_docs:   true

Function to collect user data iteratively.

        collectNextUserDataBatch = ->

            app.couch.view ALL_USER_DATA_DOC, VIEW, viewParams, (err, result) ->
                return callback err if err

If there are no more docs we have finished the backup.

                if _.isEmpty result.rows
                    debug('Backup to', provider.providerId, 'of', viewParams.skip, 'docs for user', provider.userId, 'has finished successfully.');
                    return callback()

                docs = []
                _.each result.rows, (row) ->

We unoffset the time data (which we offset during collection) and revert it to its original time.

                    doc = row?.doc
                    if doc?.utcOffset
                        doc.createdTime = doc.createdTime - doc.utcOffset if doc.createdTime
                        doc.updatedTime = doc.updatedTime - doc.utcOffset if doc.updatedTime

We never allow user tokens to escape our server. These are all stored in `providerData` or in `facebookToken`/`facebookTokenSecret` pair.

                    delete doc.providerData
                    delete doc.facebookToken
                    delete doc.facebookTokenSecret

                    docs.push doc if doc

                persistor.persistDocuments provider, docs, 'xyz', (err) ->

                    return callback(err) if err

                    # We allow other I/O to also happen before doing the next round of collections.
                    process.nextTick ->
                        viewParams.skip = viewParams.skip + result.rows.length
                        collectNextUserDataBatch()

Start collecting the data.

        collectNextUserDataBatch()

    exports.backupUserDataAsJson = backupUserDataAsJson
