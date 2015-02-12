
This module is responsible for:
 1. Creating EvernoteObject objects from external data (e.g. Everenote file metadata)
 2. Persisting EvernoteObject objects to database backend.
 3. Loading EvernoteObject objects from database backend.

For logging and other tasks we use several external modules.

    _       = require 'lodash'
    debug   = (require 'debug') 'memdive::models::EvernoteObject'
    crypto  = require 'crypto'

EvernoteObject has the following public methods:
 1. createObject - creates EvernoteObject for status from the data returned by Everenote service

    module.exports = (compound, EvernoteObject) ->

        createObject = (provider, data) ->

Each EvernoteObject has unique id based on the 'en-' prefix and a hash of Everenote user ID and its path. This in leu of inexisting Everenote ID.

            object = new compound.models.EvernoteObject {
                _id:            compound.common.dbIdCreator.createUserDataObjectId provider, data.modelId
                model:          'EvernoteObject'
                userId:         provider.userId
                modelId:        data.modelId
                utcOffset:      data.utcOffset
                extra:          data.extra
                createdTime:    data.created
                updatedTime:    data.updated
            }

            return object

        EvernoteObject.createObject = createObject
