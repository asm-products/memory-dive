
# TextObject model

This module is responsible for:

1. Creating `TextObject` objects from external data (e.g. scraped web page data)
2. Persisting `TextObject` objects to database backend.
3. Loading `TextObject` objects from database backend.

For logging and other tasks we use several external modules.

    _       = require 'lodash'
    debug   = (require 'debug') 'memdive::models::TextObject'
    crypto  = require 'crypto'

## Exported functions

TextObject has the following exported functions:

1. createObject - creates TextObject for status from the data returned by Everenote service

    module.exports = (compound, TextObject) ->

        createObject = (provider, data) ->

Each TextObject has unique id based on the 'txt-' prefix and a hash of its content. This way its uniquely recognized in the system.

            object = new compound.models.TextObject {
                _id:            compound.common.dbIdCreator.createUserDataObjectId provider, data.modelId
                model:          'TextObject'
                userId:         provider.userId
                type:           data.type
                content:        data.content
                language:       data.language
                utcOffset:      data.utcOffset
                createdTime:    data.created
            }

            return object

        TextObject.createObject = createObject
