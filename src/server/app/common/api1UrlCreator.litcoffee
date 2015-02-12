
# API v1 URL Creator

This module is responsible for creating correct URLs that point back to API v1.

## Initialization

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::common::api1UrlCreator'
    _ = require 'lodash'

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.api1UrlCreator = exports
            app.emit 'api1UrlCreatorReady'

## Constants

    API_ROOT_PATH   = '/1/api/'
    WEB_ROOT_PATH   = '/1/web/'
    API_USER_ROOT_PATH  = API_ROOT_PATH + 'user/'
    WEB_USER_ROOT_PATH  = WEB_ROOT_PATH + 'user/'

    CALENDAR_SUBPATH = 'calendar/'
    PROVIDER_SUBPATH = 'provider/'
    PROVIDER_DATA_SUBPATH = PROVIDER_SUBPATH + 'data/'
    PROVIDER_BACKUP_SUBPATH = PROVIDER_SUBPATH + 'backup/'
    AUTH_SUBPATH = 'auth/'
    DATA_AUTH_SUBPATH = AUTH_SUBPATH + 'data/'
    BACKUP_AUTH_SUBPATH = AUTH_SUBPATH + 'backup/'

## Privates

    PROVIDER_ID_TO_AUTH_SUBPATH_MAP = undefined

    getProviderSubPath = (providerId) ->

We initialize the provider ID to subpath for all known provider IDs.

        unless PROVIDER_ID_TO_AUTH_SUBPATH_MAP
            PROVIDER_ID_TO_AUTH_SUBPATH_MAP = {}
            PROVIDER_ID_TO_AUTH_SUBPATH_MAP[app.common.constants.providerId.TWITTER]        = 'twitter'
            PROVIDER_ID_TO_AUTH_SUBPATH_MAP[app.common.constants.providerId.FACEBOOK]       = 'facebook'
            PROVIDER_ID_TO_AUTH_SUBPATH_MAP[app.common.constants.providerId.DROPBOX]        = 'dropbox'
            PROVIDER_ID_TO_AUTH_SUBPATH_MAP[app.common.constants.providerId.EVERNOTE]       = 'evernote'
            PROVIDER_ID_TO_AUTH_SUBPATH_MAP[app.common.constants.providerId.GOOGLE_PLUS]    = 'google-plus'
            PROVIDER_ID_TO_AUTH_SUBPATH_MAP[app.common.constants.providerId.SLACK]          = 'slack'
            PROVIDER_ID_TO_AUTH_SUBPATH_MAP[app.common.constants.providerId.FOURSQUARE]     = 'foursquare'

        return PROVIDER_ID_TO_AUTH_SUBPATH_MAP[providerId]

## Exported functions

### getUserRootPath

`getUserRootPath` returns the URL of the root path of all the other paths that depend on the given user ID.

    getUserRootPath = (userId) ->
        return API_USER_ROOT_PATH + userId + '/'

    exports.getUserRootPath = getUserRootPath

### getCalendarUrl

`getCalendarUrl` returns the URL of the calendar root for the given user ID.

    getCalendarRootUrl = (userId) ->
        return getUserRootPath(userId) + CALENDAR_SUBPATH

    exports.getCalendarRootUrl = getCalendarRootUrl

### getCalendarMonthDayUrl

`getCalendarMonthDayUrl` returns the URL of the month/day in the calendar of the given user ID.

    getCalendarMonthDayUrl = (userId, monthDay) ->
        return getCalendarRootUrl(userId) + monthDay.month + '/' + monthDay.day

    exports.getCalendarMonthDayUrl = getCalendarMonthDayUrl

### getDataProviderAuthAddPath

`getDataProviderAuthAddPath` returns the URL of the API endpoint serving as start of provider's OAuth flow. This URL doesn't depend on user ID as some providers require fixed callback URLs.

    getDataProviderAuthAddPath = (providerId) ->
        return WEB_USER_ROOT_PATH + DATA_AUTH_SUBPATH + getProviderSubPath(providerId) + '/add'

    exports.getDataProviderAuthAddPath = getDataProviderAuthAddPath

### getDataProviderAuthCallbackPath

`getDataProviderAuthCallbackPath` returns the URL of the API endpoint serving as callback for provider's OAuth flow. This URL doesn't depend on user ID as some providers require fixed callback URLs.

    getDataProviderAuthCallbackPath = (providerId) ->
        return WEB_USER_ROOT_PATH + DATA_AUTH_SUBPATH + getProviderSubPath(providerId) + '/callback'

    exports.getDataProviderAuthCallbackPath = getDataProviderAuthCallbackPath

### getBackupProviderAuthAddPath

`getBackupProviderAuthAddPath` returns the URL of the API endpoint serving as start of provider's OAuth flow. This URL doesn't depend on user ID as some providers require fixed callback URLs.

    getBackupProviderAuthAddPath = (providerId) ->
        return WEB_USER_ROOT_PATH + BACKUP_AUTH_SUBPATH + getProviderSubPath(providerId) + '/add'

    exports.getBackupProviderAuthAddPath = getBackupProviderAuthAddPath

### getBackupProviderAuthCallbackPath

`getBackupProviderAuthCallbackPath` returns the URL of the API endpoint serving as callback for Twitter OAuth flow. This URL doesn't depend on user ID as some providers require fixed callback URLs.

    getBackupProviderAuthCallbackPath = (providerId) ->
        return WEB_USER_ROOT_PATH + BACKUP_AUTH_SUBPATH + getProviderSubPath(providerId) + '/callback'

    exports.getBackupProviderAuthCallbackPath = getBackupProviderAuthCallbackPath
