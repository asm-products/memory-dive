# Mailer module

This module is responsible for sending the plethora of emails that the service sends in different situations.

    path           = require 'path'
    mkdirp         = require 'mkdirp'
    emailTemplates = require 'swig-email-templates'
    nodemailer     = require 'nodemailer'
    debug          = require('debug')('psi-web:lib:mailer')

## Initialization

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::common::mailer'

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp
            app.common = app.common or {}
            app.common.mailer = exports
            app.emit 'mailerReady'

    transport = undefined

## Private functions

    getTransport = () ->
        return transport if transport

        switch app.common.config.MAILER_TRANSPORT
            when "PICKUP"
                debug 'PICKUP mailer transport selected'
                mkdirp.sync app.common.config.MAILER_PICKUP_DIRECTORY
                transport = nodemailer.createTransport "PICKUP",
                    directory: app.common.config.MAILER_PICKUP_DIRECTORY
            when "SMTP"
                debug 'SMTP mailer transport selected'
                transport = nodemailer.createTransport "SMTP",
                  host: app.common.config.MAILER_SMTP_ADDRESS
                  port: app.common.config.MAILER_SMTP_PORT
                  domain: app.common.config.MAILER_SMTP_DOMAIN
                  auth:
                    user: app.common.config.MAILER_SMTP_USER
                    pass: app.common.config.MAILER_SMTP_PASS
            else
                throw new Error 'Invalid or not defined mailer transport. Check mailer\'s config.transport.'

        return transport


    getSwigOptions = () ->
        return {
            root: app.common.config.MAILER_TEMPLATE_ROOT
        }

## Public functions

    sendMail = (template, to, subject, data, callback) ->
        from = app.common.config.MAILER_DEFAULT_FROM
        emailTemplates getSwigOptions(), (err, render) =>
            if err
                debug 'Error preparing email renderer', err
                return callback(err) if callback
            else
                data.baseUrl = app.common.config.BASE_URL
                render template, data, (err, html) =>
                    if err
                        debug 'Error preparing email template', err
                        return callback(err) if callback
                    else
                        mailOptions = 
                            generateTextFromHTML: true
                            from: from
                            to: to
                            subject: subject
                            html: html

                        return getTransport().sendMail mailOptions, (err, res) =>
                            callback(err, res, html) if callback

    exports.sendMail = sendMail
