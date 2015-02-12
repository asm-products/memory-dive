
# Stats controller

This controller is responsible for all `/user/:userId/stats` API endpoints.

## Initialization

    debug       = (require 'debug') 'memdive::controllers::stats'
    _           = require 'lodash'
    HttpStatus  = require 'http-status-codes'

StatsController inherits SignedInBaseController.

    StatsController = (init) ->
        SignedInBaseController.call this, init

        # We use class name for functions to avoid clashes with super or inheriting classes.
        init.before StatsController::before

    SignedInBaseController = require('./signedInBase')
    require('util').inherits StatsController, SignedInBaseController
    module.exports = StatsController

## Constants

## Private functions

## Public functions

### `GET general`

`general` function responds to `GET` requests with general user statistics.

    StatsController::general = (c) ->

        return c.res.status(HttpStatus.BAD_REQUEST).jfail('Invalid query params') unless c and c.req

        c.compound.common.userDataStatistician.general c.req.user, (err, stats) ->

            return c.redirectError c.compound.common.constants.error.USER_STATS_GENERAL_FAILED, err if err

            c.res.status(HttpStatus.OK).jsend stats
