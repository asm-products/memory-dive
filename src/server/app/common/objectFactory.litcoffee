
# `objectFactory` module

This module is responsible for returning a correct object or `nil` for the input parameters. It produces objects which might mean creating a new object or simply returning a reference to an already existing object.

## Initialization

During initialization we capture the CompoundJS app context, add this module to its `common` object and signal the rest of the app that it's ready.

    app = undefined
    constProviderId = undefined
    dropboxPersistor = undefined

    exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.objectFactory = exports
            app.emit 'objectFactoryReady'

            compound.on 'memoryDiveReady', () ->
                constProviderId = app.common.constants.providerId
                dropboxPersistor = app.persistors.dropbox

## Exported functions

### `producePersistor`

Returns a persistor object (e.g. `dropboxPersistor`) for the given backup provider ID.

    producePersistor = (providerId) ->
        switch providerId
            when constProviderId.DROPBOX then dropboxPersistor
            else undefined

    exports.producePersistor = producePersistor
