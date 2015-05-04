
# Evernote worker module

This module is responsible for:

1. Invoking collection of Evernote data
2. Transforming the said data into EvernoteObject documents
3. Requesting the persistence of the generated documents.

To perform these tasks it uses two other modules:

1. Evernote collector for collection of Evernote data.
2. EvernoteObject model for persistence of Evernote data.

Access to these modules or to be more precise objects representing these modules is obtained during the initialization of this module.

For logging and other tasks we use several external modules.

    debug   = (require 'debug') 'memdive::workers::evernote'
    frugal  = require 'frugal-couch'
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
            app.workers.evernote = exports
            app.emit 'evernoteWorkerReady'

To allow the rest of the system to actually use this module we export a single method: updateNotes.
This method is responsible for coordinating different processes that have to be performed.

This method accepts three parameters:

1. `scheduler`: the scheduler object if the invocation of this method is being done through a scheduler; otherwise undefined
2. `provider`: a UserDataProvider object for which we are collecting the data. This parameter cannot be undefined or otherwise falsy.
3. `callback`: the callback function to be invoked with err parameter in the case of error or no parameters once the process finishes.

    exports.updateNotes = (scheduler, provider, callback) ->

        debug 'updateNotes'

We ensure that the callback function exists one way or the other.

        callback = callback || (err) ->
            console.log err if err

We ensure that the input parameters are correct.

        return callback new Error('Incorrect input params') if not provider

Collection of notes and their persistence are by design two separate steps with a large cache of docs sitting in process' memory before being bulk uploaded to the database. This accomplishes two things:
 1. Uploading data in bulk is much faster.
 2. Uploading data in bulk is much cheaper (in actual money) when using DaaS service like Cloudant (which treats bulk requests as a single request)

        BULK_SIZE = 10000
        pendingDocs = []

        collectionParams =
            suppressThrottling:     app.suppressThrottling

We start collecting the data iteratively, occasionally (whenever the bulk cache gets filled) persisting the data in the database.

        savePendingDocs = (callback) ->
            console.log 'count#overwrite-bulk=1'
            console.log 'count#overwrite-bulk-docs=' + pendingDocs.length
            frugal.overwriteBulk app.couch, pendingDocs, (err) ->
                pendingDocs = []
                return callback err

Get the user object from the database as we need its timezone offset.

        app.models.User.find provider.userId, (err, user) ->
            return callback err if err

Start collecting the data.

            app.collectors.evernote.collectNotes provider, collectionParams, (err, item, next) ->
                return callback err if err

Once the collection has finished (item is falsy) we save the pending docs and issue the callback.

                return savePendingDocs callback unless item

For each retrieved item we create a new object that will be persisted to the database. Note that creator function may return undefined for items that cannot be meaningfully used.

                object = new app.models.EvernoteObject.createObject provider, {
                    modelId:    item.guid
                    utcOffset:  user.getUtcOffset()
                    created:    item.created
                    updated:    item.updated
                    extra:
                        title:      item.title
                        content:    item.content
                }

                if not _.isUndefined object
                    pendingDocs.push object
                    if pendingDocs.length >= BULK_SIZE
                        return savePendingDocs (err) ->
                            return callback err if err
                            return next()

Prevent too deep recursion by invoking `next` in the next event loop.

                setImmediate () ->
                    return next()
                , 0
