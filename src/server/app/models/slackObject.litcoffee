
# SlackObject model

This module is responsible for:

1. Creating `SlackObject` objects from external data (e.g. scraped web page data)
2. Persisting `SlackObject` objects to database backend.
3. Loading `SlackObject` objects from database backend.

For logging and other tasks we use several external modules.

    _       = require 'lodash'
    debug   = (require 'debug') 'memdive::models::SlackObject'
    crypto  = require 'crypto'

## Exported functions

### `createObject`

Creates `SlackObject` from the data returned by the service

    module.exports = (compound, SlackObject) ->

        createObject = (provider, data) ->

Each SlackObject has unique id based on the 'sl-' prefix and a hash of its content. This way its uniquely recognized in the system.

            object = new compound.models.SlackObject {
                _id:            compound.common.dbIdCreator.createUserDataObjectId provider, data.modelId
                model:          'SlackObject'
                userId:         provider.userId
                providerId:     provider._id
                channel:        data.channel
                type:           data.type
                text:           data.text
                extra:          data.extra
                utcOffset:      data.utcOffset
                createdTime:    data.timestamp
            }

            return object

        SlackObject.createObject = createObject
