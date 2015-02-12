
# Email sender module

This module is responsible for sending the plethora of emails that the service sends in different situations.

    _ = require 'lodash'

## Initialization

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::common::emailSender'

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.emailSender = exports
            app.emit 'emailSenderReady'

JavaScript months start from *zero* (while days start from 1... go figure that one out)
so we adjust months by adding 1 when returning previous/next days.

    CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1 = 1

All our transactional emails are send through the Mandrill service.

    mandrill = require('mandrill-api/mandrill')
    mandrillClient = new mandrill.Mandrill process.env.MEMORY_DIVE_MANDRILL_API_KEY

## Private functions

    getUtcDateFromMonthDay = (monthDay) ->
        new Date(Date.UTC(0, monthDay.month - CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1, monthDay.day))

## Public functions

## Early access request emails

There are two early access request emails: first is to confirm that the early access has actually been requested and the second is to confirm that... the request has been confirmed (sorry for the wording).

### Eary access request confirmation email

This email is sent when a customer requests early access to the service.

    sendNewsletterConfirmationRequestEmail = (requestObj, successCallback, errorCallback) ->
        mandrillClient.messages.sendTemplate {
            template_name: 'early-access-confirmation'
            template_content: []
            message: {
                to: [{
                    email: requestObj.email
                }]
                merge_vars: [{
                    rcpt: requestObj.email
                    vars: [{
                        name: 'confirmation_link'
                        content: process.env.MEMORY_DIVE_BASE_URL + '/1/web/newsletter/' + requestObj.id + '/confirmed'
                    }]
                }]
                auto_html: true
            }
            async: true
            ip_pool: 'Main Pool'
            send_at: ''
        }, successCallback, errorCallback

    exports.sendNewsletterConfirmationRequestEmail = sendNewsletterConfirmationRequestEmail

### Eary access registration confirmed email

This email is sent when a customer confirms his email and the issuing of the early access request.

    sendNewsletterSubscriptionConfirmedEmail = (requestObj, successCallback, errorCallback) ->
        mandrillClient.messages.sendTemplate {
            template_name: 'email-confirmed'
            template_content: []
            message: {
                to: [{
                    email: requestObj.email
                }]
                auto_html: true
            }
            async: true
            ip_pool: 'Main Pool'
            send_at: ''
        }, successCallback, errorCallback

    exports.sendNewsletterSubscriptionConfirmedEmail = sendNewsletterSubscriptionConfirmedEmail

### TODO: Early access URL email

This email is sent when the registered user is approved for the early access. It contains a link to the access entry point.


### Daily reminescence email

This email is sent once a day to all users that have it enabled. Its content for now is just a render of the user's today page.

The template of the sent email.

    sendDailyMemoriesEmail = (user, successCallback, errorCallback) ->

        return successCallback() if not user.sendDailyMemoriesEmail

        now = new Date();
        monthDay =
            month: now.getUTCMonth() + 1
            day:   now.getUTCDate()

        user.getDayData getUtcDateFromMonthDay(monthDay), (err, data) ->
            return errorCallback(err) if err
            return successCallback() if not data
            return successCallback() if not data.length
            url = app.common.config.BASE_URL + '/app/calendar/' +  monthDay.month + '/' + monthDay.day

            # calulate totals per model
            model =
                Twitter: 0
                Facebook: 0
                Dropbox: 0
                Evernote: 0
                Slack: 0,
                Foursquare: 0

            totals = _.reduce data, (model, event) ->
                model.Twitter = model.Twitter + (event.model is "TwitterObject" or 0)
                model.Facebook = model.Facebook + (event.model is "FacebookObject" or 0)
                model.Dropbox = model.Dropbox + (event.model is "DropboxObject" or 0)
                model.Evernote = model.Evernote + (event.model is "EvernoteObject" or 0)
                model.Slack = model.Slack + (event.model is "SlackObject" or 0)
                model.Foursquare = model.Foursquare + (event.model is "FoursquareObject" or 0)
                return model
            , model

            to = user.email
            subject = 'Your daily dose of memories'
            template = 'dailyMemories.html'
            data =
                email: user.email
                displayName: user.displayName
                count: data.length
                link: url
                totals: totals

            app.common.mailer.sendMail template, to, subject, data, (err, res) ->
                if err
                    debug err
                    return errorCallback()
                else
                    return successCallback()

    exports.sendDailyMemoriesEmail = sendDailyMemoriesEmail
