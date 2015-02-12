
# User provider base model

    _   = require 'lodash'

## Exported methods

    module.exports = (compound, inheritingModel) ->

        debug   = (require 'debug') 'memdive::models::UserProviderModelBase(' + inheritingModel.name + ')'

### createObject

`createObject` creates a inheritingModel.object object from the given data.

        createObject = (data) ->

            timestamp = (new Date()).getTime()

            object = new inheritingModel.object {
                _id:            compound.common.dbIdCreator[inheritingModel.dbIdCreatorName] data
                model:          inheritingModel.name
                userId:         data.userId
                providerId:     data.providerId
                providerUserId: data.providerUserId
                providerData:   data.providerData
                displayName:    data.displayName
                pictureUrl:     data.pictureUrl
                timestamp:      timestamp
                watermark:      0
            }

            return object

        inheritingModel.object.createObject = createObject

### getUserProviders

`getUserProviders` returns all the providers that the user with the given ID has configured.

        getUserProviders = (userId, callback) ->
            where =
                where:
                    userId: userId

            this.all where, callback

        inheritingModel.object.getUserProviders = getUserProviders

### putUserProvider

`putUserProvider` either adds a new data provider to the database or updates an existing provider overwriting its previous non-"key" data. The data provider document is found by searching over `data.userId`, `data.providerId` and `data.providerUserId`.

        putUserProvider = (data, callback) ->

            newProvider = createObject data

            this.findOne { where: id: newProvider.id }, (error, dbProvider) ->
                return callback error if error

To correctly update the provider's doc (if it exist) we need its `_rev`. Apart from that we always keep the `watermark` to keep track of the last time provider was used/synced/etc.

                if dbProvider
                    newProvider._rev = dbProvider._rev
                    newProvider.watermark = dbProvider.watermark

                newProvider.save callback

        inheritingModel.object.putUserProvider = putUserProvider

### getUserProvider

`getUserProvider` returns the provider data associated with the user ID, provider ID and *provider's* user ID. If there is no mapping then `null` is returned.

        getUserProvider = (userId, providerId, providerUserId, callback) ->

            data =
                userId: userId
                providerId: providerId
                providerUserId: providerUserId

            where =
                id: compound.common.dbIdCreator.createUserDataProviderObjectId data

            this.findOne where, callback

        inheritingModel.object.getUserProvider = getUserProvider
