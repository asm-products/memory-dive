
This module is responsible for:
 1. Creating DropboxObject objects from external data (e.g. Dropbox file metadata)
 2. Persisting DropboxObject objects to database backend.
 3. Loading DropboxObject objects from database backend.

For logging and other tasks we use several external modules.

    _       = require 'lodash'
    debug   = (require 'debug') 'memdive::models::DropboxObject'
    crypto  = require 'crypto'

DropboxObject has the following public methods:

1. `createObject` - creates DropboxObject for status from the data returned by Dropbox service

    module.exports = (compound, DropboxObject) ->

        createObject = (provider, data) ->

Each DropboxObject has unique id based on the 'dbox-' prefix and a hash of Dropbox user ID and its path. This in leu of inexisting Dropbox ID. `modelId` should be equal to Dropbox user ID and path but that would just lead to data duplication so we leave it as an empty string.

            # Unique ID for DropboxObject documents depends on the Dropbox file path.
            docId = compound.common.dbIdCreator.createUserDataObjectId provider, data.path

            object = new compound.models.DropboxObject {
                _id:            docId
                model:          'DropboxObject'
                modelId:        '' # See comments above.
                userId:         provider.userId
                providerId:     provider._id
                mimeType:       data.mimeType
                path:           data.path
                extra:          data.extra
                utcOffset:      data.utcOffset
                createdTime:    data.clientModifiedAt.getTime()
                updatedTime:    data.modifiedAt.getTime()
            }

            return object

        DropboxObject.createObject = createObject
