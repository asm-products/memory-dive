
# BackupProvider controller

This module provides API access to user's backup providers (services to which we backup user information)

    debug       = (require 'debug') 'memdive::controllers::backup'
    jsend       = require 'express-jsend'
    _           = require 'lodash'

## Initialization

BackupProviderController inherits ProvidersBaseController.

    BackupProviderController = (init) ->
        ProvidersBaseController.call this, init
        this.model = BackupProviderController::model

        # We use class name for functions to avoid clashes with super or inheriting classes.
        init.before BackupProviderController::before

    ProvidersBaseController = require('./providersBase')
    require('util').inherits BackupProviderController, ProvidersBaseController
    module.exports = BackupProviderController

    BackupProviderController::before = (c) ->
        @model = c.compound.models.UserBackupProvider
        c.next()

## Verbs

    BackupProviderController::getAvailableProviders = (c) ->

        common = c.compound.common
        providerId = common.constants.providerId
        urlCreator = common.api1UrlCreator

        availableProviders = [{
            providerId:         providerId.DROPBOX
            oauthStartUrl:      urlCreator.getBackupProviderAuthAddPath providerId.DROPBOX
        }]

        c.res.status(200).jsend(availableProviders)
