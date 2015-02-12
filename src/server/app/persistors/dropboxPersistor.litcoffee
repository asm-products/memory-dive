
# Dropbox persistor module

This module is responsible for persisting requested data into MemoryDive directory on Dropbox.

## Required modules

    debug   = (require 'debug') 'memdive::persistors::dropbox'
    _       = require 'lodash'
    dropbox = require 'dropbox'

## Initialization

The module is integrated into CompoundJS application.

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.persistors = app.persistors or {}
            app.persistors.dropbox = exports
            app.emit 'dropboxPersistorReady'

## Exported functions

### `persistDocuments`

This function will request persistence of the given `docs` documents into the given subdirectory `subdirectory` for the given user backup provider `provider`. Upon finishing it invokes `callback` with `(error)` parameter.

    persistDocuments = (provider, docs, subdirectory, callback) ->

        return app.common.hellRaiser.invalidArgs(arguments, callback) unless provider and docs and subdirectory and callback and _.isArray(docs)

Persisting data to Dropbox. Don't stop for anything - we want as much data as we can backed up.

        client = new dropbox.Client { token: provider.providerData.token }

        _.each docs, (doc) ->
            client.writeFile doc._id + ".json", JSON.stringify(doc), (error, stat) ->
                if error
                    debug 'Failed to backup doc', doc._id

        callback()

    exports.persistDocuments = persistDocuments
