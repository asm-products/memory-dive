
# Providers base module

This module provides access to user's providers (services that provide data or storage for say backups)

    debug       = (require 'debug') 'memdive::controllers::providersBaseController'
    jsend       = require 'express-jsend'
    _           = require 'lodash'

## Initialization

ProvidersBaseController inherits SignedInBaseController.

    ProvidersBaseController = (init) ->
        SignedInBaseController.call this, init

        # We use class name for functions to avoid clashes with super or inheriting classes.
        init.before ProvidersBaseController::before

    SignedInBaseController = require('./signedInBase')
    require('util').inherits ProvidersBaseController, SignedInBaseController
    module.exports = ProvidersBaseController

## Helpers

### `sanitizeProviderData`

`sanitizeProviderData` deletes sensitive data from the provider. For example, in general case we don't want clients getting access to the token.

    sanitizeProviderData = (provider) ->
        provider?.providerData = undefined

## Abstract properties

### `@model`

`@model` is the model object for the inherited provider. It needs to be set in `before` of that provider on each request.

## Verbs

    ProvidersBaseController::get = (c) ->

        @model.getUserProviders @user.id, (error, providers) ->
            return c.res.status(404).jfail(error) if error

            _.each providers, (provider) ->
                sanitizeProviderData provider

            c.res.status(200).jsend(providers)

    ProvidersBaseController::put = (c) ->

        data = c.req.body
        return c.res.status(404).jfail('Invalid body.') if not data or not data.providerId or not data.providerData

        @model.putUserProvider @user.id, data, (error) ->
            return c.res.status(404).jfail(error) if error
            return c.res.status(200).jsend(provider)

    ProvidersBaseController::getProvider = (c) ->

        options =
            where:
                id: c.params.providerDbId

        @model.findOne options, (error, provider) ->
            return c.res.status(404).jfail(error) if error
            sanitizeProviderData provider
            return c.res.status(200).jsend(provider)

    ProvidersBaseController::getProviderData = (c) ->

        options =
            where:
                id: c.params.providerDbId

        @model.findOne options, (error, provider) ->
            return c.res.status(404).jfail(error) if error
            data = (provider and provider.providerData) or null
            data.id = provider.providerId
            return c.res.status(200).jsend(data)

## Abstract methods

These methods have to be implemented by inheriting classes.

### `getAvailable(*)Providers`

Returns an array of objects describing available providers. Each provider object has the following properties:

* `providerId` - ID of the provider used throught the system. These correspond to provider IDs in `common.constants.providerId` object.
* `addProviderUrl` - URL of the OAuth *authorization* endpoint to which browser needs to make the request. If the client is not brower then this property can be ignored but the client has to take care of the provider's authentication flow and then at the end `PUT` the provider data into API.
* `putApiUrl` - URL of the API to which the provider data is `PUT`.

Our add-provider flow goes like this:

1. Invoke from the browser the `oauthStartUrl` of the provider object with query param of `clientCallbackUrl` in which, obviously, the client callback URL will be given.
2. Server invokes the provider's OAuth flow and captures return values (often OAuth request token and secret). It then requests the access token with the server's callback URL. At that point users gets a chance to authorize the app.
3. The server receives the callback, stores the access token for future use and finally invokes clients `clientCallbackUrl` (which was persisted in the session).

--syntax coloring hack
