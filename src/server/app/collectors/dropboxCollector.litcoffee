
# DropboxCollector module

This module is responsible for collection of user data from Dropbox.

    debug   = (require 'debug') 'memdive::collectors::dropbox'
    async   = require 'async'
    dropbox = require 'dropbox'
    _       = require 'lodash'

During initialization we perform the standard operations for all the collectors: we capture the CompoundJS app context, add this module to its set of collectors and signal the rest of the app that Dropbox collector is ready.

    app = undefined

    exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.collectors = app.collectors or {}
            app.collectors.dropbox = exports
            app.emit 'dropboxCollectorReady'

To allow the rest of the system to actually use this module we export a single method: `collectUserPhotosAndVideos`. This method accepts three parameters:

 1. `provider`: the user data provider object for which the data is being collected
 2. `params`: optional params parameter with additional flags and options (currently not used by this method)
 3. `callback`: the callback function of (err, item, next) signature through which the method passes errors and items to the client. `next` is a function interator and should be invoked by the client when it has finished processing of the item (though not of error - in that case iteration shouldn't continue).

    exports.collectUserPhotosAndVideos = (provider, params, callback) ->

Since params is optional, it may be omitted by the clients in which case in its place we will have the callback function.

        if _.isFunction(params)
            callback = params
            params = {}

        return app.common.hellRaiser.invalidArgs arguments, callback if not provider or not params or not callback

        debug 'Collecting Dropbox data for', provider.userId

        client = new dropbox.Client { token: provider.providerData.token }

Dirs keep the the list of directories that we have yet to visit. As we are reading the directories, it gets filled with new subdirectories that we find.

We start traversing the directory structure from the Photos directory as that's where most users keep their *real* photos. This means that we never collect other images but we are shooting for the 80/20 here.

        pendingDirs = ['/Photos']

Define the function to read the contents of the next pending directory from the Dropbox. This is a recursive function due to it being asynchronous *and* serial. So we invoke the next recursion only when the content of the current directory have been completely read and processes.

        readNextDir = () ->

            return callback() if pendingDirs.length == 0

            dir = pendingDirs.pop()

            debug 'calling Dropbox API readdir', dir

            client.readdir dir, (err, files, dir, detailedFiles) ->

                return callback err if err

Ensure that the answer is an array.

                return callback new DropboxError('Reply is not an array') unless _.isArray(detailedFiles)

We asynchronously but serially iterate over all the items in the reply. The client invoked through callback is required to invoke next() for the next iteration to kick in.
We separate files from directories (which we don't inform to the client). Once all the files have been processed we read all the directories. This way we save the memory as all files are processed before switching to directories (though not as much memory as we would save if all the data was read serialy)

                async.eachSeries detailedFiles, (item, next) ->

                    return next new DropboxError 'Dropbox item undefined' unless item

                    if not item.isFile
                        pendingDirs.push item.path
                        return next()

                    item.extra =
                        thumbnailUrl: client.thumbnailUrl item.path, { size:'l' }
                    return callback null, item, next
                , (err) ->
                    return callback err if err
                    readNextDir()

Start reading the directory tree.

        readNextDir()
