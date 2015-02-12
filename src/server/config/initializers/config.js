
var _    = require('lodash');
var path = require('path');

module.exports = function (compound) {

//  We create new CompoundJS module and put all configuration variables into it.

    compound.common = compound.common || {};
    compound.common.config = compound.common.config || {};

    var configConstants = [
        'BASE_URL',
        'COOKIE_SECRET',
        'COUCHDB_SERVER_URL',
        'COUCHDB_SESSIONS_STORE_URL',
        'DROPBOX_APP_KEY',
        'DROPBOX_APP_SECRET',
        'DROPBOX_BACKUP_APP_KEY',
        'DROPBOX_BACKUP_APP_SECRET',
        'EVERNOTE_CONSUMER_KEY',
        'EVERNOTE_CONSUMER_SECRET',
        'FACEBOOK_APP_ID',
        'FACEBOOK_APP_SECRET',
        'FOURSQUARE_CLIENT_ID',
        'FOURSQUARE_CLIENT_SECRET',
        'GOOGLE_PLUS_CLIENT_ID',
        'GOOGLE_PLUS_CLIENT_SECRET',
        'IRON_IO_PROJECT_ID',
        'IRON_IO_TOKEN',
        'LOCALYTICS_APP_CODE',
        'MAILER_DEFAULT_FROM',
        'MAILER_SMTP_ADDRESS',
        'MAILER_SMTP_DOMAIN',
        'MAILER_SMTP_PASS',
        'MAILER_SMTP_PORT',
        'MAILER_SMTP_USER',
        'MAILER_TRANSPORT',
        'MANDRILL_API_KEY',
        'SEGMENT_IO_WRITE_KEY',
        'SESSION_SECRET',
        'SLACK_CLIENT_ID',
        'SLACK_CLIENT_SECRET',
        'TWITTER_CONSUMER_KEY',
        'TWITTER_CONSUMER_SECRET'
    ];

//  We read the values of configuration constants from the process environment.

    _.each(configConstants, function(constant) {

//  Most environment variables have the same name as constants with 'MEMORY_DIVE_' prefix.

        var variable = 'MEMORY_DIVE_' + constant;

//  If an environment variable doesn't exist we throw an error.

        if(_.isUndefined(process.env[variable])) {
            throw new Error('Missing ' + variable + ' env variable');
        }

        compound.common.config[constant] = process.env[variable];

    });

//  Others constants we read from other enviroment variables.

    compound.common.config.PRODUCTION = process.env.NODE_ENV === 'production';

// Other constats we setup manually

    compound.common.config.MAILER_TEMPLATE_ROOT     = path.join(__dirname, "../../app/views/email/swig")
    compound.common.config.MAILER_PICKUP_DIRECTORY  = './_public/email/pickup'

    return compound.emit('configReady');

};
