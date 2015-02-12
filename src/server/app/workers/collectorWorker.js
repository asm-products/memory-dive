'use strict';

var debug = require('debug')('memdive::workers::collector');

var app;

exports.init = function (compound) {
    compound.on('ready', function(compoundApp) {
        app = compoundApp;

        app.workers = app.workers || {};
        app.workers.collector = exports;
        app.emit('collectorReady');
    });
};

//  Callback should be either undefined or function(err)
//  Disable the jshint W098 for unused "i"
/*jshint -W098*/
exports.startCollecting = function(scheduler, params, callback) {

    if(!app) {
        return;
    }

    if(!callback && typeof(params) === 'function') {
        callback = params;
        params = undefined;
    } else {
        callback = callback || function(err) { if(err) { debug(err); } };
    }

    debug('startCollecting');

//  Iterate over the users and collect data associated with them.

    app.models.User.iterate({ batchSize: 100 }, function(user, next, i) {
        if(!user) {
            next();
        } else {
            scheduler.refreshUserInfo(user, function(err, res) {
                if(err) {
                    //  TODO: Better logging.
                    debug('Refreshing user info failed', err, user._id);
                }

                next();
            });
        }
    }, callback);

};

//  Callback should be either undefined or function(err)
//  Disable the jshint W098 for unused "i"
/*jshint -W098*/
exports.sendEmails = function(scheduler, params, callback) {

    if(!app) {
        return;
    }

    if(!callback && typeof(params) === 'function') {
        callback = params;
        params = undefined;
    } else {
        callback = callback || function(err) { if(err) { debug(err); } };
    }

    debug('sendEmails');

    app.models.User.iterate({ batchSize: 100 }, function(user, next, i) {
        if(!user) {
            next();
        } else {
            app.common.emailSender.sendDailyMemoriesEmail(user, function(responses) {
                    next();
                }, function(err) {
                    console.log('Error sending daily email to', user && user.email, ':', err);
                    next();
                });
        }
    }, callback);

};
