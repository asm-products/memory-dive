
# DataProvider controller

This module provides API access to user's data providers (services from which we collect information)

    debug       = (require 'debug') 'memdive::controllers::provider'
    jsend       = require 'express-jsend'
    _           = require 'lodash'

## Initialization

DataProviderController inherits ProvidersBaseController.

    DataProviderController = (init) ->
        ProvidersBaseController.call this, init

        # We use class name for functions to avoid clashes with super or inheriting classes.
        init.before DataProviderController::before

    ProvidersBaseController = require('./providersBase')
    require('util').inherits DataProviderController, ProvidersBaseController
    module.exports = DataProviderController

    DataProviderController::before = (c) ->
        @model = c.compound.models.UserDataProvider
        c.next()

## Verbs

    DataProviderController::getAvailableProviders = (c) ->

        common = c.compound.common
        providerId = common.constants.providerId
        urlCreator = common.api1UrlCreator

        availableProviders = [{
            providerId:         providerId.FACEBOOK
            oauthStartUrl:      urlCreator.getDataProviderAuthAddPath providerId.FACEBOOK
        }, {
            providerId:         providerId.TWITTER
            oauthStartUrl:      urlCreator.getDataProviderAuthAddPath providerId.TWITTER
        }, {
            providerId:         providerId.DROPBOX
            oauthStartUrl:      urlCreator.getDataProviderAuthAddPath providerId.DROPBOX
        }, {
            providerId:         providerId.EVERNOTE
            oauthStartUrl:      urlCreator.getDataProviderAuthAddPath providerId.EVERNOTE
        }, {
            providerId:         providerId.SLACK
            oauthStartUrl:      urlCreator.getDataProviderAuthAddPath providerId.SLACK
        }, {
            providerId:         providerId.FOURSQUARE
            oauthStartUrl:      urlCreator.getDataProviderAuthAddPath providerId.FOURSQUARE
        }]

        c.res.status(200).jsend(availableProviders)
