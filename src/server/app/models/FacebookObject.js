'use strict';

//  We are working with CouchDb API and it uses non-camel case identifiers
//  so we disable the warning W106.
/*jshint -W106*/

var _       = require('lodash')
  , debug   = require('debug')('memdive::models::FacebookObject')
  , frugal  = require('frugal-couch');

var undefinedUnless = function(o) {
    var value = o;
    var evaluate = function() {
        return value;
    };
    evaluate.and = function(p) {
        if(!_.isUndefined(value)
            && _.isObject(value)) {
            value = value[p];
        }

        return evaluate;
    };
    return evaluate;
};

var deepDefined = function() {
    if(!arguments
        || arguments.length === 0) {
        return undefined;
    }

    var value = arguments[0];
    for(var i = 1; i < arguments.length; ++i) {
        if(_.isUndefined(value)
            || !_.isObject(value)) {
            return undefined;
        }

        value = value[arguments[i]];
    }

    return value;
};

module.exports = function (compound, FacebookObject) {

    var saveBulk = function(docs, callback) {

        console.log('count#overwrite-bulk=1');
        console.log('count#overwrite-bulk-docs=' + docs.length);
        frugal.overwriteBulk(compound.couch, docs, callback);

    };
    FacebookObject.saveBulk = saveBulk;

    var createObject = function(provider, data, type) {

        var updatedTime = new Date(data.updated_time).getTime();
        var createdTime = new Date(data.created_time).getTime();
        if(!createdTime) {
            console.log('ERROR: failed Date parsing of FB object created_time:', data.created_time);
        }

        var object = new compound.models.FacebookObject({
            _id:            compound.common.dbIdCreator.createUserDataObjectId(provider, data.id),
            //  We have to specify the model as bulk loading won't add that automatically.
            model:          'FacebookObject',
            modelId:        data.id,
            userId:         provider.userId,
            type:           type,
            name:           data.name,
            fromId:         deepDefined(data, 'from', 'id'),
            source:         data.source,
            picture:        data.picture,
            link:           data.link,
            utcOffset:      data.utcOffset,
            //  We get times as ISO strings so we have to parse them and then save them as UNIX epoch.
            createdTime:    createdTime,
            updatedTime:    updatedTime
        });

        return object;
    };

    //  Functions for working with photos.
    var createPhotoDoc = function(provider, data) {
        return createObject(provider, data, 'photo');
    };
    FacebookObject.createPhotoDoc = createPhotoDoc;

    //  Functions for working with videos.
    var createVideoDoc = function(provider, data) {
        var object = createObject(provider, data, 'video');
        object.extra = { embedHtml: data.embed_html };
        return object;
    };
    FacebookObject.createVideoDoc = createVideoDoc;

    //  Functions for working with likes.
    var createLikeDoc = function(provider, data) {
        var object = createObject(provider, data, 'like');
        object.extra = { cover: data.cover };
        return object;
    };
    FacebookObject.createLikeDoc = createLikeDoc;

    //  Functions for working with posts.
    var createPostDoc = function(provider, data) {


//  We don't collect photo "statuses" as those are already present as photo objects.

        if(data.type === 'photo') {
            return undefined;
        }

        var object = createObject(provider, data, 'post');
        object.extra = {
            type:           data.type,
            story:          data.story,
            message:        data.message,
            link:           data.link,
            description:    data.description,
            caption:        data.caption,
            name:           data.name,
            objectId:       data.object_id
        };

        return object;
    };
    FacebookObject.createPostDoc = createPostDoc;

    //  Functions for working with notes.
    var createNoteDoc = function(provider, data) {
        var object = createObject(provider, data, 'note');
        object.extra = {
            subject:        data.subject,
            messageHtml:    data.message,
        };

        return object;
    };
    FacebookObject.createNoteDoc = createNoteDoc;

    //  Functions for working with statuses.
    var createStatusDoc = function(provider, data) {
        var object = createObject(provider, data, 'status');
        object.extra = {
            message:        data.message
        };

        return object;
    };
    FacebookObject.createStatusDoc = createStatusDoc;

};
