
# GooglePlusAuth controller

## Initialization

This controller is responsible for authenticating the user with Google+ service.

    debug       = (require 'debug') 'memdive::controllers::googlePlusAuth'
    crypto      = require 'crypto'
    jsend       = require 'express-jsend'
    googleapis  = require 'googleapis'
    request     = require 'superagent'

The app's Google+ configuration is read from the process environment.

    CLIENT_ID       = process.env.MEMORY_DIVE_GOOGLE_PLUS_CLIENT_ID
    CLIENT_SECRET   = process.env.MEMORY_DIVE_GOOGLE_PLUS_CLIENT_SECRET

Callback URL depends on the request user.

    getCallbackUrl = (c) ->
        return process.env.MEMORY_DIVE_BASE_URL + c.compound.common.api1UrlCreator.getDataProviderAuthCallbackPath(c.compound.common.constants.providerId.GOOGLE_PLUS)

`GooglePlusAuthController` inherits `ProviderAuthBaseController`.

    GooglePlusAuthController = (init) ->
        ProviderAuthBaseController.call this, init
        return

    ProviderAuthBaseController = require('./providerAuthBase')
    require('util').inherits GooglePlusAuthController, ProviderAuthBaseController
    module.exports = GooglePlusAuthController

## Constants

    GOOGLE_PLUS_PEOPLE_ME_URL = 'https://www.googleapis.com/plus/v1/people/me'
    MILLISECONDS_IN_SECOND = 1000

## Private functions

## Public functions

`add` is invoked when the user requests to add a new Google+ data source. This is not an API call but a web page that will redirect the client to Google+'s URL for further authentication.

* `clientCallbackSuccessUrl` is URL to which the control should be returned once the process finishes successfully.
* `clientCallbackFailureUrl` is URL to which the control should be returned on any errors.

--

    GooglePlusAuthController::add = (c) ->

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

The way Google+ OAuth is created we cannot guard against cross-site request forgery as it doesn't allow *any* way to pass CSRF token to it and from it back to us.

Preserve tokens and callback URLs in the user's session so that they can be accessed from the `callback`.

        c.req.session.googlePlusClientCallbackSuccessUrl = successUrl
        c.req.session.googlePlusClientCallbackFailureUrl = failureUrl

We use google's API to authorize (not Passport as its useless for our case). We request offline access so that we can collect the data on the server-side where the user will obviously never log in.

        oauth2Client = new googleapis.auth.OAuth2 CLIENT_ID, CLIENT_SECRET, getCallbackUrl(c)
        url = oauth2Client.generateAuthUrl {
            access_type:    'offline'
            scope:          'https://www.googleapis.com/auth/plus.login'
        }

Redirect the user to provider's authentication and authorization page.

        c.res.redirect url

`callback` is invoked by GooglePlus itself during the OAuth authorization process.

    GooglePlusAuthController::callback = (c) ->

        return c.redirectError 300, c.req.query.error + ': ' + c.req.query.error_description if c.req.query.error

Google sends us the code through request query parameters.

        return c.res.redirect c.req.session.googlePlusClientCallbackFailureUrl unless c.req.query.code

        oauth2Client = new googleapis.auth.OAuth2 CLIENT_ID, CLIENT_SECRET, getCallbackUrl(c)
        oauth2Client.getToken c.req.query.code, (err, tokens) ->

            return callback err if err

Once we get the access token we need to get actual information about the user's added account. We get this through `https://www.googleapis.com/plus/v1/people/me` URL.

            request.get(GOOGLE_PLUS_PEOPLE_ME_URL).query({ access_token: tokens.access_token }).end (err, res) ->
                return callback err if err
                return callback new Error 'Missing user ID in their profile' if not res or not res.body or not res.body.id

                providerUserId = res.body.id
                expiresIn = new Date().getTime() + MILLISECONDS_IN_SECOND * tokens.expires_in

                userProviderData =
                    userId:         c.req.user.id
                    providerId:     c.compound.common.constants.providerId.GOOGLE_PLUS
                    providerUserId: providerUserId
                    providerData:
                        token:          tokens.access_token
                        refreshToken:   tokens.refresh_token
                        expiresIn:      expiresIn
                        tokenType:      tokens.token_type

Post the data to the database, overwriting any previous data matching the same userId, providerId and providerUserId.

                c.compound.models.UserDataProvider.putUserProvider userProviderData, (error, providerObject) ->

                    # TODO: Move this to error handling module.
                    return c.res.redirect c.req.session.googlePlusClientCallbackFailureUrl if error

                    #  On successfully added auth we schedule collecting the data and send the user to their profile page.
                    c.compound.common.scheduler.refreshUserDataProviderInfo providerObject, (err) ->
                        return debug 'Collection of user Google+ data failed', err if err

                    # At the end we redirect the client back to where it requested.
                    c.res.redirect c.req.session.googlePlusClientCallbackSuccessUrl
