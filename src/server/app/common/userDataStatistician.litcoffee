
# userDataStatistician module

This module is responsible for checking, adding, manipulating, modifying and other generalized operations on user data (that is all the documents that were generated by the user either on MOFS or on other sources).

### Initialization

    _       = require 'lodash'
    debug   = (require 'debug') 'memdive::common::userDataStatistician'

    app = undefined

The module is integrated into CompoundJS application.

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.userDataStatistician = exports
            app.emit 'userDataStatisticianReady'

## Constants

    VIEW = 'view'

    USER_DATA_VIEW_YEAR_DOC = 'userDataPerYear'
    USER_DATA_VIEW_YEAR_USER_ID_INDEX = 0
    USER_DATA_VIEW_YEAR_UTC_YEAR_INDEX = 1
    USER_DATA_VIEW_YEAR_UTC_MONTH_INDEX = 2
    USER_DATA_VIEW_YEAR_MODEL_INDEX = 3
    USER_DATA_VIEW_YEAR_POSIX_TIME_INDEX = 4

JavaScript months start from *zero* (while days start from 1... go figure that one out)
so we adjust months by adding 1 when returning previous/next days.

    CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1 = 1

## Private functions

## Public functions

### `general`

`general` function returns an object with the following user statistics:

* `yearMonth`:  total docs per year/month separated per their type

It takes the following parameters:

* `user`:     `User` model object representing the user whose documents we will be updating.
* `callback`: function of `(error)` signature invoked with error or with no parameters if no error occurrs.

--

    general = (user, callback) ->

We want **all** the user's docs so our start and end key are the beginning and the end of `user.id` space (see CouchDb documentation for explanation of `{}`)

        viewParams =
                startkey:       [user.id]
                endkey:         [user.id, {}]

We are only interested in [user, year, month, model] part of the key so the reduce group level is +1 on model index (level).

                reduce:         true
                group_level:    USER_DATA_VIEW_YEAR_MODEL_INDEX + 1

        return app.couch.view USER_DATA_VIEW_YEAR_DOC, VIEW, viewParams, (err, result) ->
            return callback err if err

            reduce = (counters, item) ->
                key = item.key
                year = key[USER_DATA_VIEW_YEAR_UTC_YEAR_INDEX];
                month = key[USER_DATA_VIEW_YEAR_UTC_MONTH_INDEX] + CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1
                model = key[USER_DATA_VIEW_YEAR_MODEL_INDEX]

                current = _.last(counters)
                if not current or current.year isnt year or current.month isnt month
                    current =
                        year: year
                        month: month
                        count: 0

                    counters.push current

                current[model] = item.value
                current.count = current.count + item.value

                return counters

            stats = _.reduce result.rows, reduce, []

            callback err, stats

    exports.general = general