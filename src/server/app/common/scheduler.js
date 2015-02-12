
'use strict';

var async    = require('async');
var debug    = require('debug')('memdive::workers::scheduler');

var thisScheduler = exports;

var app;

var PROVIDER_WORKER_FUNCTIONS = {};

exports.init = function(compound) {

    compound.on('ready', function(compoundApp) {
        app = compoundApp;

        app.workers = app.workers || {};
        app.common.scheduler = exports;
        app.emit('schedulerReady');

//  Map provider IDs with their corresponding worker/collector functions.

        compoundApp.on('memoryDiveReady', function() {

            var providerId = app.common.constants.providerId;

            PROVIDER_WORKER_FUNCTIONS[providerId.FACEBOOK] = exports.collectFacebookProviderUserInfo;
            PROVIDER_WORKER_FUNCTIONS[providerId.DROPBOX] = exports.collectDropboxProviderUserInfo;
            PROVIDER_WORKER_FUNCTIONS[providerId.EVERNOTE] = exports.collectEvernoteProviderUserInfo;
            PROVIDER_WORKER_FUNCTIONS[providerId.TWITTER] = exports.collectTwitterProviderUserInfo;
            PROVIDER_WORKER_FUNCTIONS[providerId.GOOGLE_PLUS] = exports.collectGooglePlusProviderUserInfo;
            PROVIDER_WORKER_FUNCTIONS[providerId.SLACK] = exports.collectSlackProviderUserInfo;
            PROVIDER_WORKER_FUNCTIONS[providerId.FOURSQUARE] = exports.collectFoursquareProviderUserInfo;

        });

    });

};

var jobId = {
    REFRESH_USER_INFO:      1,
    REFRESH_ALL_USER_INFO:  2,
    REFRESH_USER_DATA_PROVIDER_INFO:    3,
    COLLECT_FACEBOOK_PROVIDER_USER_INFO: 1000,
    COLLECT_TWITTER_PROVIDER_USER_INFO:  1001,
    COLLECT_DROPBOX_PROVIDER_USER_INFO:  1002,
    COLLECT_EVERNOTE_PROVIDER_USER_INFO: 1003,
    COLLECT_GOOGLE_PLUS_PROVIDER_USER_INFO: 1004,
    COLLECT_SLACK_PROVIDER_USER_INFO:    1005,
    COLLECT_FOURSQUARE_PROVIDER_USER_INFO: 1006,
    SEND_DAILY_MAILS: 2000,
    BACKUP_ALL_USER_DATA_TO_ALL_PROVIDERS: 3000,
    BACKUP_USER_DATA_TO_ALL_PROVIDERS: 3001,
    BACKUP_USER_DATA_AS_JSON: 3002
};

exports.jobId = jobId;

exports.schedule = function(f) {

//  TODO: Move this to a real MQ. For now we simulate it within the Node.

//  NOTE: We don't use process.nextTick on purpose - all the I/O will wait until
//      all the functions scheduled in such a way finish. This means that say signin
//      function scheduling update of user data will wait, even though it's ready
//      to return the data to caller, until all scheduled tasks finish.

    setTimeout(function() {
        try {
            f();
        }
        catch(err) {

//  TODO: Inform the rest of the system about it... maybe?

            console.log(err.stack);
        }
    }, 0);
};

//  Schedules the execution of the action together with its params.

var pushFifo = function(action, params, callback) {

    if(!callback && typeof(params) === 'function') {
        callback = params;
        params = undefined;
    }

    callback = callback || function(err) { if(err) { debug(err); }};

    switch(action) {
    case jobId.REFRESH_USER_INFO:

//  Collect data for all user's data providers and invoke in parallel refreshing of their data.
//  Only once all the collection is finished (or an error occurred) will the `callback` be invoked.

        app.models.UserDataProvider.all({
            where: {
                userId: params.id
            }
        }, function(error, providers) {
            if(error) {
                return callback(error);
            }

            //  Invoke in parallel refreshening of the user's provider's data.
            async.each(providers, exports.refreshUserDataProviderInfo, callback);
        });

        break;
    case jobId.REFRESH_ALL_USER_INFO:
        exports.schedule(function() {
            app.workers.collector.startCollecting(thisScheduler, params, callback);
        });
        break;
    case jobId.REFRESH_USER_DATA_PROVIDER_INFO:
        var workerFn = PROVIDER_WORKER_FUNCTIONS[params.providerId];
        if(workerFn) {
            workerFn(params, callback);
        } else {
            process.nextTick(function() {
                callback(new Error('Unknown user data provider action: ' + params.providerId));
            });
        }
        break;
    case jobId.COLLECT_FACEBOOK_PROVIDER_USER_INFO:
        exports.schedule(function() {
            app.workers.facebook.updateInfo(thisScheduler, params, callback);
        });
        break;
    case jobId.COLLECT_TWITTER_PROVIDER_USER_INFO:
        exports.schedule(function() {
            app.workers.twitter.updateUserStatuses(thisScheduler, params, callback);
        });
        break;
    case jobId.COLLECT_DROPBOX_PROVIDER_USER_INFO:
        exports.schedule(function() {
            app.workers.dropbox.updateUserPhotosAndVideos(thisScheduler, params, callback);
        });
        break;
    case jobId.COLLECT_EVERNOTE_PROVIDER_USER_INFO:
        exports.schedule(function() {
            app.workers.evernote.updateNotes(thisScheduler, params, callback);
        });
        break;
    case jobId.COLLECT_SLACK_PROVIDER_USER_INFO:
        exports.schedule(function() {
            app.workers.slack.updateMessages(thisScheduler, params, callback);
        });
        break;
    case jobId.COLLECT_FOURSQUARE_PROVIDER_USER_INFO:
        exports.schedule(function() {
            app.workers.foursquare.updateCheckIns(thisScheduler, params, callback);
        });
        break;
    case jobId.SEND_DAILY_MAILS:
        exports.schedule(function() {
            app.workers.collector.sendEmails(thisScheduler, params, callback);
        });
        break;
    case jobId.BACKUP_ALL_USER_DATA_TO_ALL_PROVIDERS:
        app.models.User.iterate({ batchSize: 100 }, function(user, next, i) {
            if(!user) {
                next();
            } else {
                thisScheduler.backupUserDataToAllProviders(user, function(err) {
                    if(err) {
                        //  TODO: Better logging.
                        debug('Backup of user data failed', err, user._id);
                    }

                    next();
                });
            }
        }, callback);
        break;
    case jobId.BACKUP_USER_DATA_TO_ALL_PROVIDERS:
        app.models.UserBackupProvider.all({
            where: {
                userId: params.id
            }
        }, function(error, providers) {
            if(error) {
                return callback(error);
            }

            async.each(providers, exports.backupUserDataToProvider, callback);
        });
        break;
    case jobId.BACKUP_USER_DATA_AS_JSON:
        exports.schedule(function() {
            app.workers.backupAdmin.backupUserDataAsJson(thisScheduler, params, callback);
        });
        break;
    default:
        process.nextTick(function() {
            callback(new Error('Unknown scheduler action: ' + action));
        });
        break;
    }
};

exports.pushFifo = function(jobId, params, callback) {
    pushFifo(jobId, params, callback);
};

exports.refreshUserInfo = function(params, callback) {
    pushFifo(jobId.REFRESH_USER_INFO, params, callback);
};

exports.refreshUserDataProviderInfo = function(params, callback) {
    pushFifo(jobId.REFRESH_USER_DATA_PROVIDER_INFO, params, callback);
};

exports.refreshAllUserInfo = function(params, callback) {
    pushFifo(jobId.REFRESH_ALL_USER_INFO, params, callback);
};

exports.collectFacebookProviderUserInfo = function(params, callback) {
    pushFifo(jobId.COLLECT_FACEBOOK_PROVIDER_USER_INFO, params, callback);
};

exports.collectTwitterProviderUserInfo = function(params, callback) {
    pushFifo(jobId.COLLECT_TWITTER_PROVIDER_USER_INFO, params, callback);
};

exports.collectGooglePlusProviderUserInfo = function(params, callback) {
//    pushFifo(jobId.COLLECT_GOOGLE_PLUS_PROVIDER_USER_INFO, params, callback);
    //  TODO: Add this.
    callback();
};

exports.collectDropboxProviderUserInfo = function(params, callback) {
    pushFifo(jobId.COLLECT_DROPBOX_PROVIDER_USER_INFO, params, callback);
};

exports.collectEvernoteProviderUserInfo = function(params, callback) {
    pushFifo(jobId.COLLECT_EVERNOTE_PROVIDER_USER_INFO, params, callback);
};

exports.collectSlackProviderUserInfo = function(params, callback) {
    pushFifo(jobId.COLLECT_SLACK_PROVIDER_USER_INFO, params, callback);
};

exports.collectFoursquareProviderUserInfo = function(params, callback) {
    pushFifo(jobId.COLLECT_FOURSQUARE_PROVIDER_USER_INFO, params, callback);
};

exports.sendDailyEmails = function(params, callback) {
    pushFifo(jobId.SEND_DAILY_MAILS, params, callback);
};

exports.backupAllUserDataToAllProviders = function(params, callback) {
    pushFifo(jobId.BACKUP_ALL_USER_DATA_TO_ALL_PROVIDERS, params, callback);
};

exports.backupUserDataToAllProviders = function(params, callback) {
    pushFifo(jobId.BACKUP_USER_DATA_TO_ALL_PROVIDERS, params, callback);
};

exports.backupUserDataToProvider = function(params, callback) {
    pushFifo(jobId.BACKUP_USER_DATA_AS_JSON, params, callback);
};
