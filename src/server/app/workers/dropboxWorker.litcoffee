
# dropboxWorker module

This module is responsible for:

1. Invoking collection of Dropbox data
2. Transforming the said data into DropboxObject documents
3. Requesting the persistence of the generated documents.

To perform these tasks it uses two other modules:

1. Dropbox collector for collection of Dropbox data.
2. DropboxObject model for persistence of Dropbox data.

Access to these modules or to be more precise objects representing these modules is obtained during the initialization of this module.

For logging and other tasks we use several external modules.

    debug   = (require 'debug') 'memdive::workers::dropbox'
    frugal  = require 'frugal-couch'
    _       = require 'lodash'

## Initialization

During the initialization of the module we perform several duties:

1. Capturing of the CompoundJS's app context so we can later access modules and collectors.
2. Registering the worker with the same app context so that other parts of the app can use us.
3. Signaling the rest of the app that this module is ready so that the app can proceed.

    app = undefined

    exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.workers = app.workers or {}
            app.workers.dropbox = exports
            app.emit 'dropboxWorkerReady'

## Constants

Arbitrarily large size of bulk uploading of documents.

    BULK_SIZE = 10000

## Public functions

To allow the rest of the system to actually use this module we export a single method: `updateUserPhotosAndVideos`.
This method is responsible for coordinating different processes that have to be performed.

This method accepts three parameters:

1. `scheduler`: the scheduler object if the invocation of this method is being done through a scheduler; otherwise undefined
2. `provider`: a UserDataProvider object for which we are collecting the data. This parameter cannot be undefined or otherwise falsy.
3. `callback`: the callback function to be invoked with err parameter in the case of error or no parameters once the process finishes.

    exports.updateUserPhotosAndVideos = (scheduler, provider, callback) ->

        debug 'updateUserPhotosAndVideos'

We ensure that the callback function exists one way or the other.

        callback = callback || (err) ->
            console.log err if err

We ensure that the input parameters are correct.

        return app.common.hellRaiser.invalidArgs arguments, callback if not provider

Get the user object from the database as we need its timezone offset.

        app.models.User.find provider.userId, (err, user) ->
            return callback err if err
            return app.common.hellRaiser.userNotFound provider.userId, callback if not user

All collected items will be assigned user's current UTC offset.

            utcOffset = user.getUtcOffset()

Collection of statuses and their persistence are by design two separate steps with a large cache of docs sitting in process' memory before being bulk uploaded to the database. This accomplishes two things:

 1. Uploading data in bulk is much faster.
 2. Uploading data in bulk is much cheaper (in actual money) when using DaaS service like Cloudant (which treats bulk requests as a single request)

            pendingDocs = []

We start collecting the data iteratively, occasionally (whenever the bulk cache gets filled) persisting the data in the database.

            savePendingDocs = (callback) ->
                console.log 'count#overwrite-bulk=1'
                console.log 'count#overwrite-bulk-docs=' + pendingDocs.length
                frugal.overwriteBulk app.couch, pendingDocs, (err) ->
                    pendingDocs = []
                    return callback err

            app.collectors.dropbox.collectUserPhotosAndVideos provider, (err, item, next) ->
                return callback err if err

Once the collection has finished (item is falsy) we save the pending docs and issue the callback.

                return savePendingDocs callback unless item

For each retrieved status we create a new object that will be persisted to the database. Note that creator function may return undefined for items that cannot be meaningfully used.

Before we create the object we add it the `utcOffset` we got from the user.

                item.utcOffset = utcOffset

                object = new app.models.DropboxObject.createObject provider, item
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
