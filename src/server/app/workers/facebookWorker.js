'use strict';

//  We are working with Facebook API and it uses non-camel case identifiers
//  so we disable the warning W106.
/*jshint -W106*/

var graph = require('fbgraph')
  , _     = require('lodash')
  , debug = require('debug')('memdive::workers::facebook')
  , async = require('async');

var options = {
    timeout:  60000
  , pool:     { maxSockets:  Infinity }
  , headers:  { connection:  "keep-alive" }
};

var app;
var collector;

exports.init = function(compound) {
    compound.on('ready', function(compoundApp) {
        app = compoundApp;

        app.workers = app.workers || {};
        app.workers.facebook = exports;
        app.on('memoryDiveReady', function() {
            //  Get the collector once the system is ready.
            collector = app.collectors.facebook;
        });
        app.emit('facebookWorkerReady');
    });
};

//  Callback should be either undefined or function(err)
exports.updateInfo = function(scheduler, provider, callback) {

//  To update the complete user info (from FB at least) we collect the user's photo and then update all its
//  FB items.

    updateProviderDocs(provider, [{
            collector:  collector.collectUploadedPhotos,
            creator:    app.models.FacebookObject.createPhotoDoc
        }, {
            collector:  collector.collectTaggedPhotos,
            creator:    app.models.FacebookObject.createPhotoDoc
        }, {
            collector:  collector.collectUploadedVideos,
            creator:    app.models.FacebookObject.createVideoDoc
        }, {
            collector:  collector.collectTaggedVideos,
            creator:    app.models.FacebookObject.createVideoDoc
        }, {
            collector:  collector.collectLikes,
            creator:    app.models.FacebookObject.createLikeDoc
        }, {
            collector:  collector.collectPosts,
            creator:    app.models.FacebookObject.createPostDoc
        }, {
            collector:  collector.collectNotes,
            creator:    app.models.FacebookObject.createNoteDoc
        }, {
            collector:  collector.collectStatuses,
            creator:    app.models.FacebookObject.createStatusDoc
        }], callback);

};

exports.updateUploadedPhotos = function(provider, callback) {

    debug('updateUploadedPhotos', provider.providerUserId);

    updateProviderDocs(provider, [{
        collector:  collector.collectUploadedPhotos,
        creator:    app.models.FacebookObject.createPhotoDoc
    }], callback);

};

exports.updateTaggedPhotos = function(provider, callback) {

    debug('updateTaggedPhotos', provider.providerUserId);

    updateProviderDocs(provider, [{
        collector:  collector.collectTaggedPhotos,
        creator:    app.models.FacebookObject.createPhotoDoc
    }], callback);

};

exports.updateUploadedVideos = function(provider, callback) {

    debug('updateUploadedVideos', provider.providerUserId);

    updateProviderDocs(provider, [{
        collector:  collector.collectUploadedVideos,
        creator:    app.models.FacebookObject.createVideoDoc
    }], callback);

};

exports.updateTaggedVideos = function(provider, callback) {

    debug('updateTaggedVideos', provider.providerUserId);

    updateProviderDocs(provider, [{
        collector:  collector.collectTaggedVideos,
        creator:    app.models.FacebookObject.createVideoDoc
    }], callback);

};

exports.updateLikes = function(provider, callback) {

    debug('updateLikes', provider.providerUserId);

    updateProviderDocs(provider, [{
        collector:  collector.collectLikes,
        creator:    app.models.FacebookObject.createLikeDoc
    }], callback);

};

exports.updatePosts = function(provider, callback) {

    debug('updatePosts', provider.providerUserId);

    updateProviderDocs(provider, [{
        collector:  collector.collectPosts,
        creator:    app.models.FacebookObject.createPostDoc
    }], callback);

};

exports.updateNotes = function(provider, callback) {

    debug('updateNotes', provider.providerUserId);

    updateProviderDocs(provider, [{
        collector:  collector.collectNotes,
        creator:    app.models.FacebookObject.createNoteDoc
    }], callback);

};

exports.updateStatuses = function(provider, callback) {

    debug('updateStatuses', provider.providerUserId);

    updateProviderDocs(provider, [{
        collector:  collector.collectStatuses,
        creator:    app.models.FacebookObject.createStatusDoc
    }], callback);

};

function invokeCallback(callback, err, res) {

    if(callback) {
        callback(err, res);
    } else if(err) {
        //  If there was an error and no callback at least let's log it.
        //  TODO: Make a SysEvent.
        console.log('dump err to console:', err);
    }

}

var updateProviderDocs = function(provider, sources, callback) {

    debug('updateProviderDocs', provider.providerUserId);

//  If callback is undefined we dump the data to console.

    callback = callback || function(err) { if(err) { debug(err); } };

//  Check that we have somewhat well defined input parameters.

    if(_.isUndefined(provider)
        || _.isUndefined(sources)
        || !_.isArray(sources)
        || _.isEmpty(sources)) {
        return callback(new Error('invalid input params', provider, sources));
    }

//  For collections we use bulk uploading as a) it's much faster and b) it's much, much cheaper if using DaaS
//  One additional advantage is that this will update the documents that may have changed since we are assinging
//  stable IDs based on Facebook's stable ID.
//  We upload the docs by a 10,000 each as our docs on average are about 0.5 Kb long so that's 5 Mb in cache.

    var BULK_SIZE = 10000;
    var pendingDocs = [];
    var utcOffset = 0;
    var totalDocsCollected = 0;

//  Get the user object from the database as we need its timezone offset.

    return app.models.User.find(provider.userId, function(err, user) {

        if(err) {
            return callback(err);
        }

        if(!user) {
            return app.common.hellRaiser.userNotFound(provider.userId, callback);
        }

//  All collected items will be assigned user's current UTC offset.

        utcOffset = user.getUtcOffset();

//  We process all sources serially to simplify our life in testing.
//  It is, in general case, of no consequence to actual performance
//  as our servers are more likely than not to have full hands (we hope)

        return async.eachSeries(sources, updateFromSource, function(err) {

//  Once all the sources have been processed we save the pending documents.

            if(err) {
                return callback(err);
            }

            var docsToSave = pendingDocs;
            pendingDocs = [];

            saveDocs(docsToSave, function(err) {
                callback(err, {
                    docsCollected: totalDocsCollected
                });
            });

        });
    });

    function saveDocs(docs, callback) {

        app.models.FacebookObject.saveBulk(docs, function(err, result) {
            debug('collected', docs.length, 'docs for', provider.providerUserId);
            return callback(err);
        });

    }

    function updateFromSource(source, asyncCallback) {

        //  Get the current source data and move the index to the next source.
        var collector = source.collector;
        var creator = source.creator;

        collector(provider, function(err, item, next) {

//  If an error happend, we pass the error to asynch which will stop the processing.
//  This means that pending docs are not collected.

            if(err) {
                return asyncCallback(err);
            }

//  No more items, we have finished the collection.

            if(!item) {
                return asyncCallback();
            }

            totalDocsCollected = totalDocsCollected + 1;

//  Add utcOffset to the item so that it's considered by creator function.

            item.utcOffset = utcOffset;

//  Create the document from the collected data.

            var doc = creator(provider, item);

//  We skip the item whenever the creator function decides not to use it.

            if(!_.isUndefined(doc)) {

//  Add the new document to the array of pending docs. If we have reached the
//  BULK_SIZE threshold then save the docs and continue collecting the data.

                pendingDocs.push(doc);
                if(pendingDocs.length >= BULK_SIZE) {

//  We send the pending docs to saving while others continue collecting.

                    var docsToSave = pendingDocs;
                    pendingDocs = [];

                    return saveDocs(docsToSave, function(err) {
                        if(err) {
                            return callback(err);
                        }

                        return next();
                    });
                }
            }

//  Move to the next collected item.

            return next();

        });
    }
};

var updateUserPicture = function(user, callback) {

    debug('updatePicture', user.facebookId);

    return graph
        .setOptions(options)
        .get(user.username, {
            access_token: user.facebookToken,
            fields: 'picture.height(500).width(380).type(large)'
        }, graphCallback);

    function graphCallback(err, res) {
        if(err) {
            debug('get picture error', user.facebookId, err);

            invokeCallback(callback, err);
        } else {
            if(_.isEqual(user.picture, res.picture.data)) {
                debug('picture not changed', provider.providerUserId);

                invokeCallback(callback, err);
            } else {
                debug('updating picture', provider.providerUserId);

                user.picture = res.picture.data;
                user.save(function(err, savedUser) {
                    if(err) {
                        debug('updating picture error', user.facebookId, err);
                    }

                    invokeCallback(callback, err, savedUser);
                });
            }
        }
    }

};

exports.updateUserPicture = updateUserPicture;
