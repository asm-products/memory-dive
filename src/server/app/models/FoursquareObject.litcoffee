
# FoursquareObject model

This module is responsible for:

1. Creating `FoursquareObject` objects from external data (e.g. scraped web page data)
2. Persisting `FoursquareObject` objects to database backend.
3. Loading `FoursquareObject` objects from database backend.

For logging and other tasks we use several external modules.

    _       = require 'lodash'
    debug   = (require 'debug') 'memdive::models::FoursquareObject'
    crypto  = require 'crypto'

## Exported functions

### `createObject`

Creates `FoursquareObject` from the data returned by the service

    module.exports = (compound, FoursquareObject) ->

        createObject = (provider, data) ->

Each FoursquareObject has unique id based on the '4s-' prefix and a hash of its content. This way its uniquely recognized in the system.

            object = new compound.models.FoursquareObject {
                _id:            compound.common.dbIdCreator.createUserDataObjectId provider, data.modelId
                model:          'FoursquareObject'
                modelId:        data.modelId
                userId:         provider.userId
                providerId:     provider._id
                type:           data.type
                text:           data.text
                extra:          data.extra
                utcOffset:      data.utcOffset
                createdTime:    data.createdAt
            }

            return object

        FoursquareObject.createObject = createObject
