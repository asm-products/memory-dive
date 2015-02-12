
# TwitterAuth controller

This controller is responsible for authorizing the user with Twitter service.

## Constants

The app's provider configuration is read from the process environment.

    CONSUMER_KEY        = process.env.MEMORY_DIVE_TWITTER_CONSUMER_KEY
    CONSUMER_SECRET     = process.env.MEMORY_DIVE_TWITTER_CONSUMER_SECRET

We use a specialized strategy name to avoid any conflicts with *authentication* strategy we use with through a different mechanism.

    PASSPORT_STRATEGY_NAME = 'memory-dive-twitter-auth'

## Initialization

    _           = require 'lodash'
    debug       = (require 'debug') 'memdive::controllers::twitterAuth'
    api1UrlCreator = require '../common/api1UrlCreator'
    constants   = require '../common/constants'
    passport    = require 'passport'

TwitterAuthController inherits ProviderAuthBaseController.

    TwitterAuthController = (init) ->
        ProviderAuthBaseController.call this, init
        configPassport()
        return

    ProviderAuthBaseController = require('./providerAuthBase')
    require('util').inherits TwitterAuthController, ProviderAuthBaseController
    module.exports = TwitterAuthController

## Private functions

    getCallbackUrl = ->
        return process.env.MEMORY_DIVE_BASE_URL + api1UrlCreator.getDataProviderAuthCallbackPath(constants.providerId.TWITTER)

### `configPassport`

`configPassport` will configure Passport to use our own specialized version of authorization.

    configPassport = ->
        Strategy = require('passport-twitter').Strategy

        strategyOptions =
            consumerKey:    CONSUMER_KEY
            consumerSecret: CONSUMER_SECRET
            callbackURL:    getCallbackUrl()

        strategy = new Strategy(strategyOptions, (token, tokenSecret, profile, done) ->
            # We send to our own handler the data we got from the Passport.
            done null, null, {
                token:          token
                tokenSecret:    tokenSecret
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

    TwitterAuthController::add = (c) ->

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

        passport.authorize(PASSPORT_STRATEGY_NAME)(c.req, c.res, c.next)

`callback` is invoked by the provider during the OAuth authroization process.

    TwitterAuthController::callback = (c) ->

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
                providerId:     constants.providerId.TWITTER
                providerUserId: info.profile.id
                displayName:    info.profile.username
                pictureUrl:     _.result(_.first(info.profile.photos), 'value')
                providerData:
                    token:          info.token
                    tokenSecret:    info.tokenSecret

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
