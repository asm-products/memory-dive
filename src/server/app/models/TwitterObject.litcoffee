
This module is responsible for:
 1. Creating TwitterObject objects from external data (e.g. Twitter statuses data)
 2. Persisting TwitterObject objects to database backend.
 3. Loading TwitterObject objects from database backend.

For logging and other tasks we use several external modules.

    _       = require 'lodash'
    debug   = (require 'debug') 'memdive::models::TwitterObject'

TwitterObject has the following public methods:
 1. createStatusObject - creates TwitterObject for status from the status data returned by Twitter service

    module.exports = (compound, TwitterObject) ->

        createObject = (provider, data) ->

The text of the statuses is either the text for personal statuses or the text of the original tweet for retweets.

            retweetedText = data.retweeted_status && data.retweeted_status.text
            retweetedName = data.retweeted_status && data.retweeted_status.user && data.retweeted_status.user.screen_name

            object = new compound.models.TwitterObject {
                _id:            compound.common.dbIdCreator.createUserDataObjectId(provider, data.id)
                model:          'TwitterObject'
                modelId:        data.id
                userId:         provider.userId
                type:           'status'
                text:           retweetedText || data.text
                extra:
                    retweeted:      !_.isUndefined(retweetedText)
                    by:             retweetedName || (data.user && data.user.screen_name)
                utcOffset:      data.utcOffset
                # We get times as ISO strings so we have to parse them and then save them as UNIX epoch.
                createdTime:    new Date(data.created_at).getTime()
            }

            return object

        createStatusObject = (userId, data) ->
            object = createObject userId, data, 'status'
            return object

        TwitterObject.createStatusObject = createStatusObject
