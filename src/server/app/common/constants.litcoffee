
# Constants module

This module exports all the constants used in the system.

## Initialization

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::common::constants'

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.constants = exports
            app.emit 'constantsReady'

## Exported constants

    exports.db =
        USER_DATA_VIEW_DOC:     'userData'
        USER_TEXT_SEARCH_DOC:   'userText'

    exports.providerId =
        TWITTER:     'tw'
        FACEBOOK:    'fb'
        DROPBOX:     'dbox'
        EVERNOTE:    'en'
        GOOGLE_PLUS: 'gp'
        TEXT_IMPORT: 'txt' # Email, web scraping, other plain text import.
        SLACK:       'sl'
        FOURSQUARE:  '4s'

    exports.error =
        NO_ERROR:                               0
        INVALID_ARGS:                           1
        DROPBOX_AUTH_CALLBACK_FAILED:           1000
        DROPBOX_AUTH_CSRF_MISMATCH:             1001
        DROPBOX_AUTH_BEARER_TOKEN_REQUEST_FAILED:   1002
        DROPBOX_AUTH_BEARER_TOKEN_EXCHANGE_FAILED:  1003
        DROPBOX_AUTH_VERIFICATION_FAILED:       1004
        DROPBOX_AUTH_BAD_VERIFICATION_ANSWER:   1005
        REQUEST_USER_UNDEFINED:                 1900
        USER_NOT_FOUND:                         1901
        USER_UPDATE_FAILED:                     2000
        USER_GET_PREVIOUS_DAY_FAILED:           2001
        USER_GET_NEXT_DAY_FAILED:               2002
        USER_DATA_PROVIDER_SAVE_FAILED:         3000
        USER_DATA_PROVIDER_FINDONE_FAILED:      3001
        USER_TEXT_SEARCH_FAILED:                3002
        USER_STATS_GENERAL_FAILED:              3003
        TWITTER_GET_AUTH_REQUEST_TOKEN_FAILED:  4000
        TWITTER_GET_ACCESS_TOKEN_FAILED:        4001
        TWITTER_VERIFY_CREDENTIALS_FAILED:      4002
        TWITTER_UPDATE_USER_DATA_FAILED:        4003
        TWITTER_AUTH_CSRF_MISMATCH:             4004
        EVERNOTE_GET_REQUEST_TOKEN_FAILED:      20141221
        EVERNOTE_AUTH_START_FAILED:             20141222
        EVERNOTE_VERIFY_CREDENTIALS_FAILED:     20141223
        EVERNOTE_AUTH_CSRF_MISMATCH:            20141224
        GOOGLE_PLUS_GET_REQUEST_TOKEN_FAILED:   20140427
        GOOGLE_PLUS_VERIFY_CREDENTIALS_FAILED:  20140428
        EVERNOTE_AUTH_CSRF_MISMATCH:            20140429
        FOURSQUARE_AUTH_ERROR:                  20140608
