
# Event model

This module is responsible for:

1. Creating `Event` objects from external data (e.g. sign up, signed in, etc.)
2. Persisting `Event` objects to database backend.
3. Loading `Event` objects from database backend.

For logging and other tasks we use several external modules.

    _       = require 'lodash'
    debug   = (require 'debug') 'memdive::models::Event'
    crypto  = require 'crypto'

## Private functions

    getTimestamp = ->

We make special allowances for life simplification during testing by always setting
timestamp and createdOn to 0. This way there is no postprocessing of nocks or of
actual tests.

        if(process.env.NODE_ENV == 'test')
            return 0
        else
            return new Date().getTime()


## Exported functions

### `create`

Creates `Event` from the data returned by the service

    module.exports = (compound, Event) ->

        createObject = (userId, type, data) ->

            object = new compound.models.Event {
                model:          'Event'
                userId:         userId
                type:           type
                text:           data
                timestamp:      getTimestamp()
            }

            return object

        Event.createObject = createObject

        type =
            USER_SIGNED_UP:  'user-signed-up'
            USER_SIGNED_IN:  'user-signed-in'
            USER_SIGNED_OUT: 'user-signed-out'

        Event.type = type
