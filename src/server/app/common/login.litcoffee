
# Login

We use Facebook services to provide the login for our users. If the user doesn't have Facebook or doesn't want to connect their Facebook account then they cannot access our service.

    _ = require 'lodash'

## Initialization

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::common::login'

    app = undefined
    tracker = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.login = exports
            app.emit 'loginReady'

            compound.on 'memoryDiveReady', ->
                tracker = app.common.tracker

## Constants

    APP_ROOT = '/app'

## Public methods

### `signIn`

The `signIn` method is invoked from different controllers whenever the signing is again necessary. The `c` variable stands for Compound which is the object sent to controllers by CompoundJS framework. Furthermore the controllers can specify the redirect URL to which they want the user redirected after a successful login. If redirect URL is not specified then `c.req.session.redirect` is used.

    signIn = (c, redirectUrl) ->
        debug 'signing in with redirectUrl', redirectUrl
        c.req.session.redirect = redirectUrl if not _.isUndefined redirectUrl
        c.res.redirect '/auth/facebook'

    exports.signIn = signIn

### `signedIn`

The `signedIn` method is invoked when the user has successfully signed in *and* this has been confirmed by subsequent checks of the invoking controller.

    signedIn = (c) ->
        tracker.userSignedIn(c.req.user) if c.req.user

        redirectUrl = c.req.query?.redirect or APP_ROOT
        debug('signed in, redirecting to', redirectUrl)

        c.res.redirect redirectUrl

    exports.signedIn = signedIn
