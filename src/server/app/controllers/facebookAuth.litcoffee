
# FacebookAuth controller

This controller is responsible for authorizing the user with Facebook service.

## Constants

The app's Facebook configuration is read from the process environment.

    APP_ID      = process.env.MEMORY_DIVE_FACEBOOK_APP_ID
    APP_SECRET  = process.env.MEMORY_DIVE_FACEBOOK_APP_SECRET

We use a specialized strategy name to avoid any conflicts with *authentication* strategy we use with through a different mechanism.

    PASSPORT_STRATEGY_NAME = 'memory-dive-facebook-auth'

## Initialization

    _           = require 'lodash'
    debug       = (require 'debug') 'memdive::controllers::facebookAuth'
    api1UrlCreator = require '../common/api1UrlCreator'
    constants   = require '../common/constants'
    passport    = require 'passport'

FacebookAuthController inherits ProviderAuthBaseController.

    FacebookAuthController = (init) ->
        ProviderAuthBaseController.call this, init
        configPassport()
        return

    ProviderAuthBaseController = require('./providerAuthBase')
    require('util').inherits FacebookAuthController, ProviderAuthBaseController
    module.exports = FacebookAuthController

## Private functions

    getCallbackUrl = ->
        return process.env.MEMORY_DIVE_BASE_URL + api1UrlCreator.getDataProviderAuthCallbackPath(constants.providerId.FACEBOOK)

### `configPassport`

`configPassport` will configure Passport to use our own specialized version of authorization.

    configPassport = ->
        Strategy = require('passport-facebook').Strategy

        strategyOptions =
            clientID:       APP_ID
            clientSecret:   APP_SECRET
            callbackURL:    getCallbackUrl()

        strategy = new Strategy(strategyOptions, (accessToken, refreshToken, profile, done) ->
            # We send to our own handler the data we got from the Passport.
            done null, null, {
                accessToken:    accessToken
                refreshToken:   refreshToken
                profile:        profile
            }
        )
        strategy.name = PASSPORT_STRATEGY_NAME

        passport.use strategy

## Public functions

`add` is invoked when the user requests to add a new data source. This is not an API call but a web page that redirect the client to providers's URL for further authentication.

* query param `clientCallbackSuccessUrl` is URL to which the control should be returned once the process finishes successfully.
* query param `clientCallbackFailureUrl` is URL to which the control should be returned on any errors.

Both of these query params are obligatory.

    FacebookAuthController::add = (c) ->

Check that we have received all the parameters that we need.

        queryParams = c and c.req and c.req.query
        successUrl = queryParams and queryParams.clientCallbackSuccessUrl
        failureUrl = queryParams and queryParams.clientCallbackFailureUrl
        if not successUrl or not failureUrl
            if failureUrl
                c.res.redirect failureUrl
            else
                # TODO: There are two types of errors JSON and browser. In this case we redirect back to browser.
                # Provide a common error handler module to perform correct error handling.
                c.redirect '/app/error?code=500&description=Bad OAuth client configuration'
            return

        c.req.session.clientCallbackSuccessUrl = successUrl
        c.req.session.clientCallbackFailureUrl = failureUrl

        passport.authorize(PASSPORT_STRATEGY_NAME, { scope: 'basic_info' })(c.req, c.res, c.next)

`callback` is invoked by the provider during the OAuth authroization process.

    FacebookAuthController::callback = (c) ->

        successUrl = c.req.session.clientCallbackSuccessUrl
        failureUrl = c.req.session.clientCallbackFailureUrl
        if not successUrl or not failureUrl
            if failureUrl
                c.res.redirect failureUrl
            else
                # TODO: Provide a common error handler module to perform correct error handling.
                c.redirect '/app/error?code=500&description=Bad OAuth client configuration'
            return

Our specialized authorization handler will save the new (or updated) provider's data and invoke data collection.

        handleAuthorization = (err, user, info) ->
            return c.redirect failureUrl if err

            providerData =
                userId:         c.req.user.id
                providerId:     constants.providerId.FACEBOOK
                providerUserId: info.profile.id
                displayName:    info.profile.displayName
                providerData:
                    token:          info.accessToken
                    refreshToken:   info.refreshToken

            c.compound.collectors.facebook.collectPicture providerData, (error, picture) ->

                # We don't fail on this error, we simply emit a warning.
                if not error and picture
                    providerData.pictureUrl = picture.url
                else
                    console.warn 'Failed to retrieve Facebook user picture: ', error

                c.compound.models.UserDataProvider.putUserProvider providerData, (error, provider) ->

                    # TODO: Move this to error handling module.
                    return c.res.redirect failureUrl if error

                    #  On successfully added auth we add collecting the data.
                    c.compound.common.scheduler.refreshUserDataProviderInfo provider, (err) ->
                        debug 'Collection of user data failed', provider, err if err

                    c.res.redirect successUrl

Request authorization after the authentication.

        passport.authorize(PASSPORT_STRATEGY_NAME, {
            successRedirect: c.req.session.clientCallbackSuccessUrl
            failureRedirect: c.req.session.clientCallbackFailureUrl
        }, handleAuthorization)(c.req, c.res, c.next)
