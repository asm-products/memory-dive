
# Search controller

This controller is responsible for offering full text search to API users without leaking any data.

## Initialization

    debug       = (require 'debug') 'memdive::controllers::search'
    _           = require 'lodash'
    HttpStatus  = require 'http-status-codes'

SearchController inherits SignedInBaseController.

    SearchController = (init) ->
        SignedInBaseController.call this, init

        # We use class name for functions to avoid clashes with super or inheriting classes.
        init.before SearchController::before

    SignedInBaseController = require('./signedInBase')
    require('util').inherits SearchController, SignedInBaseController
    module.exports = SearchController

## Constants

## Private functions

## Public functions

### `GET text`

`text` function serves `GET` requests with provided query. To prevent data leakage it adds `userId` condition to the query.

    SearchController::text = (c) ->

        return c.res.status(HttpStatus.BAD_REQUEST).jfail('Invalid query params') unless c and c.req and c.req.query and c.req.query.q

        c.compound.common.userDataGovernor.searchUserText c.req.user, c.req.query.q, (err, docs, bookmark) ->

            return c.redirectError c.compound.common.constants.error.USER_TEXT_SEARCH_FAILED, err if err

            c.res.status(HttpStatus.OK).jsend {
                docs: docs
                bookmark: bookmark
            }
