'use strict';

var _ = require('lodash');

//  We are working with Facebook API and it uses non-camel case identifiers
//  so we disable the warning W106.
/*jshint -W106*/

var graph = require('fbgraph')
  , debug = require('debug')('memdive::collectors::facebook')
  , async = require('async');

var options = {
    timeout:  60000
  , pool:     { maxSockets:  Infinity }
  , headers:  { connection:  "keep-alive" }
};

var app;

exports.init = function(compound) {

    compound.on('ready', function(compoundApp) {
        app = compoundApp;

        app.collectors = app.collectors || {};
        app.collectors.facebook = exports;
        app.emit('facebookCollectorReady');
    });

};

var collectData = function(params, callback) {

    if(!callback) {
        throw new Error('Callback required');
    }

    var graphParams = _.cloneDeep(params.params) || {};
    graphParams.limit = graphParams.limit || 25;
    graphParams.access_token = graphParams.access_token || params.token;

//  Start walking the graph through readData callback.

    return graph
        .setOptions(options)
        .get(params.facebookId + '/' + params.collection, graphParams, readData);

//  This function walks the page after page of items by the virtue of FB's RESTful API.

    function readData(err, res) {

//  We stop on any and all errors.

        if(err) {
            debug('fbgraph error', err);
            return callback(new GraphError(err));
        }

        if(!res || !res.data) {
            callback(new Error('no response data'));
            return;
        }

//  Iterate through the items serially and asynchronously as we don't know
//  what the callback will be doing with our data.

        var items = res.data;
        async.eachSeries(
            items,
            function(item, next) {
                if(!item) {
                    next('item undefined');
                } else {
                    //  The next will be called by the invoking function.
                    callback(err, item, next);
                }
            },

//  When iteration finishes we either continue on to the next page or stop due to an error.

            function(err) {
                if(err) {
                    callback(err);
                } else {
                    //  Continue on to the next page.
                    nextPage(res);
                }
            }

        );

    }

//  Retrieve the next page data if there is such. If there is no next page, end the iteration.

    function nextPage(res) {
        if(res.paging
            && res.paging.next) {
            graph
                .setOptions(options)
                .get(res.paging.next, graphParams, readData);
        } else {
            //  End of iteration.
            callback();
        }
    }

};

//  Collects user data from the collection, invoking callback for each item *serially*.

exports.collectProviderData = function(provider, collection, params, callback) {

    debug('collectProviderData', provider.providerUserId, collection, params);

    if(!provider) {
        throw new Error('provider required');
    }

    collectData({
        token: provider.providerData && provider.providerData.token,
        facebookId: provider.providerUserId,
        collection: collection,
        params: params
    }, callback);

};

var photoFields = 'id,from,name,link,source,picture,created_time,updated_time';

exports.collectUploadedPhotos = function(provider, callback) {
    exports.collectProviderData(provider, 'photos', { type: 'uploaded', fields: photoFields }, callback);
};

exports.collectTaggedPhotos = function(provider, callback) {
    exports.collectProviderData(provider, 'photos', { type: 'tagged', fields: photoFields }, callback);
};

var videoFields = 'id,from,name,description,source,picture,embed_html,created_time,updated_time';

exports.collectUploadedVideos = function(provider, callback) {
    exports.collectProviderData(provider, 'videos', { type: 'uploaded', fields: videoFields }, callback);
};

exports.collectTaggedVideos = function(provider, callback) {
    exports.collectProviderData(provider, 'videos', { type: 'tagged', fields: videoFields }, callback);
};

exports.collectLikes = function(provider, callback) {
    exports.collectProviderData(provider, 'likes', { fields: 'id,name,link,cover,created_time' }, callback);
};

exports.collectPosts = function(provider, callback) {
    exports.collectProviderData(provider, 'posts', { fields: 'id,from,story,picture,type,message,link,description,caption,name,object_id,created_time,updated_time' }, callback);
};

exports.collectNotes = function(provider, callback) {
    exports.collectProviderData(provider, 'notes', { fields: 'id,from,subject,message,created_time,updated_time' }, callback);
};

exports.collectStatuses = function(provider, callback) {

//  "created_time" field is, for some reason known only to FB, unavailable for this query.
//  We handle this by equating created_time with updated_time but there are also checks during object
//  creation and indexation.

    exports.collectProviderData(provider, 'statuses', { fields: 'id,from,message,updated_time' }, function(err, item, next) {

        //  As noted above make created_time to be the same as updated_time.
        if(!err && item && !item.created_time && item.updated_time) {
            item.created_time = item.updated_time;
        }

        return callback(err, item, next);

    });
};

var collectPicture = function(provider, callback) {

    debug('collectPicture', provider.providerUserId);

    return graph
        .setOptions(options)
        .get(provider.providerUserId, {
            access_token: provider.providerData.token,
            fields: 'picture.height(500).width(380).type(large)'
        }, function(err, res) {
            if(err || !res || !res.picture ) {
                return callback(err);
            }

            callback(err, res.picture.data);
        });

};

exports.collectPicture = collectPicture;

//  Specialized error returned from Graph calls.
function GraphError(err) {
    Error.call(this);
    this.message = err.message;
    this.type = err.type;
    this.code = err.code;
    this.error_subcode = err.error_subcode;
}

require('util').inherits(GraphError, Error);
