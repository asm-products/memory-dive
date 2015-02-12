
# dbIdCreator module

This module is repsonsible for uniform creation of database IDs for all needs of the system.

    _ = require 'lodash'
    crypto  = require 'crypto'

## Initialization

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::common::dbIdCreator'

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.dbIdCreator = exports
            app.emit 'dbIdCreatorReady'

## Public functions

### `create`

This function creates a (statistically) unique ID from the given ID prefix and a hash digest of all (including the prefix just to make it easier) arguments passed to it.

    create = (prefix) ->
        hash = crypto.createHash('sha')

        _(arguments).filter((arg) -> not _.isUndefined(arg)).each (arg) ->
            # With stringify we ensure that we have a string to hash.
            hash.update JSON.stringify(arg)

        return prefix + '-' + hash.digest('hex')

    exports.create = create

### `createUserDataObjectId`

This specialized function creates a (statistically) unique ID from the given `UserDataProvider` object and unique ID for the service object.

    createUserDataObjectId = (provider, objectProviderId) ->
        return create provider.providerId, provider.userId, provider.providerUserId, objectProviderId

    exports.createUserDataObjectId = createUserDataObjectId

### `createUserDataProviderObjectId`

This specialized function creates a (statistically) unique ID for a `UserDataProvider` object from user's ID, provider's ID and provider user's ID (that is - the ID with which the user is identified with the provider)

    createUserDataProviderObjectId  = (providerData) ->
        return create providerData.providerId, providerData.userId, providerData.providerUserId

    exports.createUserDataProviderObjectId = createUserDataProviderObjectId

### `createUserBackupProviderObjectId`

This specialized function creates a (statistically) unique ID for a `UserBackupProvider` object from user's ID, provider's ID and provider user's ID (that is - the ID with which the user is identified with the backup provider)
We add the `'backup'` argument to avoid clashes with same data providers having all the other params.

    createUserBackupProviderObjectId  = (providerData) ->
        return create providerData.providerId, 'backup', providerData.userId, providerData.providerUserId

    exports.createUserBackupProviderObjectId = createUserBackupProviderObjectId
