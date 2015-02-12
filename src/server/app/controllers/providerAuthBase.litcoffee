
# ProviderAuthBase controller

Our ProviderAuthBase keeps the stuff common for all our controllers that require the user to be signed in:

- It checks that the user is signed in and forwards unsigned users to signing in.

    'use strict'

## Initialization

    BaseController = require './base'

    ProviderAuthBaseController = (init) ->
        BaseController.call this, init

        # We use class name for functions to avoid clashes with super or inheriting classes.
        init.before(ProviderAuthBaseController.prototype.before)

    require('util').inherits(ProviderAuthBaseController, BaseController)

Before any action check that the user is signed in.

    ProviderAuthBaseController.prototype.before = (c) ->

Redirect to error 401 - Unauthorized - if the user isn't signed in

        return c.redirectError 401, 'Please sign in.', '/error' if not c.req.user

We set the user for the controller and all inheriting controllers.

        this.user = c.req.user

        c.next()

## Exports

    module.exports = ProviderAuthBaseController
