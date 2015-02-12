/*
 db/schema.js contains database schema description for application models
 by default (when using jugglingdb as ORM) this file uses database connection
 described in config/database.json. But it's possible to use another database
 connections and multiple different schemas, docs available at

 http://railwayjs.com/orm.html

 Example of model definition:

 define('User', function () {
     property('email', String, { index: true });
     property('password', String);
     property('activated', Boolean, {default: false});
 });

 Example of schema configured without config/database.json (heroku redistogo addon):
 schema('redis', {url: process.env.REDISTOGO_URL}, function () {
     // model definitions here
 });

*/

/* jshint -W071, -W117, -W098 */
var User = describe('User', function () {
    property('facebookId', String, { index: true });
    property('displayName', String);
    property('username', String);
    property('email', String);
    property('facebookToken', String);
    property('facebookTokenSecret', String);
    property('birthday', String);
    property('location', Object);
    property('hometown', Object);
    property('picture', Object);
    property('timezone', String);
    property('utcOffset', Number);
    property('sendDailyMemoriesEmail', Boolean, { default: false });
    property('createdOn', Number);
    property('timestamp', Number);
    set('restPath', pathTo.Users);
});

User.validatesPresenceOf('facebookId');

var FacebookObject = describe('FacebookObject', function () {
    //  To be able to explicity specify the CouchDb id we have to define it as an explicit part of the schema.
    property('_id', String);
    property('_rev', String);
    property('userId', String);
    property('modelId', String);
    property('type', String);
    property('name', String);
    property('fromId', Number);
    property('source', String);
    property('picture', String);
    property('link', String);
    property('extra', Object);
    property('utcOffset', Number);
    property('createdTime', Number);
    property('updatedTime', Number);
    set('restPath', pathTo.FacebookObjects);
});

FacebookObject.validatesPresenceOf('modelId');

var TwitterObject = describe('TwitterObject', function () {
    //  To be able to explicity specify the CouchDb id we have to define it as an explicit part of the schema.
    property('_id', String);
    property('_rev', String);
    property('userId', String);
    property('modelId', String);
    property('type', String);
    property('text', String);
    property('extra', Object);
    property('utcOffset', Number);
    property('createdTime', Number);
    set('restPath', pathTo.TwitterObject);
});

TwitterObject.validatesPresenceOf('modelId');

var DropboxObject = describe('DropboxObject', function () {
    //  To be able to explicity specify the CouchDb id we have to define it as an explicit part of the schema.
    property('_id', String);
    property('_rev', String);
    property('userId', String);
    property('providerId', String);
    property('modelId', String);
    property('mimeType', String);
    property('path', String);
    property('extra', Object);
    property('utcOffset', Number);
    property('createdTime', Number);
    set('restPath', pathTo.DropboxObject);
});

DropboxObject.validatesPresenceOf('modelId');

var EvernoteObject = describe('EvernoteObject', function () {
    //  To be able to explicity specify the CouchDb id we have to define it as an explicit part of the schema.
    property('_id', String);
    property('_rev', String);
    property('userId', String);
    property('modelId', String);
    property('extra', Object);
    property('utcOffset', Number);
    property('createdTime', Number);
    property('updatedTime', Number);
    set('restPath', pathTo.EvernoteObject);
});

EvernoteObject.validatesPresenceOf('modelId');

var TextObject = describe('TextObject', function () {
    //  To be able to explicity specify the CouchDb id we have to define it as an explicit part of the schema.
    property('_id', String);
    property('_rev', String);
    property('userId', String);
    property('source', String);
    property('type', String);
    property('content', Object);
    property('language', String);
    property('utcOffset', Number);
    property('createdTime', Number);
    set('restPath', pathTo.TextObject);
});

TextObject.validatesPresenceOf('userId');

var SlackObject = describe('SlackObject', function () {
    //  To be able to explicity specify the CouchDb id we have to define it as an explicit part of the schema.
    property('_id', String);
    property('_rev', String);
    property('userId', String);
    property('providerId', String);
    property('modelId', String);
    property('channel', String);
    property('type', String);
    property('text', String);
    property('extra', Object);
    property('utcOffset', Number);
    property('createdTime', Number);
    set('restPath', pathTo.SlackObject);
});

SlackObject.validatesPresenceOf('userId');

var FoursquareObject = describe('FoursquareObject', function () {
    //  To be able to explicity specify the CouchDb id we have to define it as an explicit part of the schema.
    property('_id', String);
    property('_rev', String);
    property('userId', String);
    property('providerId', String);
    property('modelId', String);
    property('extra', Object);
    property('utcOffset', Number);
    property('createdTime', Number);
    set('restPath', pathTo.FoursquareObject);
});

SlackObject.validatesPresenceOf('userId');

var Event = describe('Event', function () {
    property('userId', String);
    property('type', String);
    property('data', Object);
    property('timestamp', Number);
    set('restPath', pathTo.Event);
});

Event.validatesPresenceOf('userId');

var ObjectMetadata = describe('ObjectMetadata', function () {
    property('userId', String);
    property('type', String);
    property('objectId', String);
    property('metadata', Object);
    property('createdOn', Number);
    set('restPath', pathTo.ObjectMetadata);
});

var UserDataProvider = describe('UserDataProvider', function() {
    //  To be able to explicity specify the CouchDb id we have to define it as an explicit part of the schema.
    property('_id', String);
    property('_rev', String);
    property('userId', String, { index: true });
    property('providerId', String);
    property('providerUserId', String);
    property('providerData', Object);
    property('displayName', String);
    property('pictureUrl', String);
    property('watermark', Number);
    set('restPath', pathTo.ObjectMetadata);
});

var UserBackupProvider = describe('UserBackupProvider', function() {
    //  To be able to explicity specify the CouchDb id we have to define it as an explicit part of the schema.
    property('_id', String);
    property('_rev', String);
    property('userId', String, { index: true });
    property('providerId', String);
    property('providerUserId', String);
    property('providerData', Object);
    property('displayName', String);
    property('pictureUrl', String);
    property('watermark', Number);
    set('restPath', pathTo.ObjectMetadata);
});

var NewsletterSubscription = describe('NewsletterSubscription', function () {
    property('email', String, { index: true });
    property('status', String);
    property('createdOn', Number);
    property('timestamp', Number);
    set('restPath', pathTo.NewsletterSubscription);
});

NewsletterSubscription.validatesPresenceOf('email');
