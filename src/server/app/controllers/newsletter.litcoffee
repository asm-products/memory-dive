
# Newsletter controller

This controller is responsible for accepting newsletter registration confirmations.

    debug       = (require 'debug') 'memdive::controllers::newsletter'
    _           = require 'lodash'

## Initialization

NewsletterController inherits BaseController.

    NewsletterController = (init) ->
        BaseController.call this, init

        # We use class name for functions to avoid clashes with super or inheriting classes.
        init.before NewsletterController::before

    BaseController = require('./base')
    require('util').inherits NewsletterController, BaseController
    module.exports = NewsletterController

    NewsletterSubscriptionConfirmed = (c) ->
        c.redirect '/newsletter/confirmed-thank-you'

## Private functions

We store all early access requests in our backend but only if it doesn't exist already. If it exists then we just resend the email but once (as email has a cost for us).

    storeRegistration = (c) ->
        email = c.req?.body?.email
        app = c.compound
        newRequest = app.models.NewsletterSubscription.createObject { email: email }
        app.models.NewsletterSubscription.findOrCreate {
            where:
                email: email
        }, newRequest, (err, requestObj) ->
            return if err or not requestObj or requestObj.status != 'new'

Whatever may happen with the sending of email we update the request object to `unconfirmed`. The reasoning for this is that either the email will get through or the data is bad and it *cannot* be confirmed and sending the request to the same address would simply be wasting resources.

            requestObj.status = 'unconfirmed'
            requestObj.save()

            app.common.emailSender.sendNewsletterConfirmationRequestEmail requestObj, (responses) ->
                # TODO: Display user with an error if the email address is incorrect.
                if not responses or not _.isArray(responses) or responses.length != 1
                    return console.log 'sendNewsletterConfirmationRequestEmail sent unexpected responses', responses
                response = _.first responses
                if not response or (response.status != 'sent' and response.status != 'queued')
                    return console.log 'sendNewsletterConfirmationRequestEmail sent an error response', response
                return
            , (error) ->
                # TODO: Display user with an error.
                console.log 'sendNewsletterConfirmationRequestEmail error', error

## Available actions

### `subscribe`

    NewsletterController::subscribe = (c) ->
        storeRegistration c
        c.res.redirect '/newsletter/please-confirm'

### `:id/confirmed`

`confirmed` is invoked when the user clicks on the link from the confirmation email. It updates the newsletter subscriptio to `confirmed` status and sends a confirmation email.

    NewsletterController::confirmed = (c) ->

        c.compound.models.NewsletterSubscription.find c.params.id, (err, requestObj) ->
            if err or not requestObj
                console.log 'NewsletterSubscription.find failed (1):', err, requestObj, c and c.params and c.params.id
                return NewsletterSubscriptionConfirmed c

            # Don't do anything if the email has already been confirmed.
            return if requestObj.status == 'confirmed'

            # The status has been confirmed so we first update the db.
            requestObj.status = 'confirmed'
            requestObj.save (err) ->
                console.log 'NewsletterSubscription.save() error', err

                # We send the confirmation email only after the db has been updated
                c.compound.common.emailSender.sendNewsletterSubscriptionConfirmedEmail requestObj, (responses) ->
                    # TODO: analyze if the response indicates an error
                    NewsletterSubscriptionConfirmed c
                , (err) ->
                    console.log 'NewsletterSubscriptionConfirmed error', err
                    NewsletterSubscriptionConfirmed c
