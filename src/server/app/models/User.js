
'use strict';

//  We are working with CouchDb API and it uses non-camel case identifiers
//  so we disable the warning W106.
/*jshint -W106*/

var _       = require('lodash')
  , debug   = require('debug')('memdive::models::user')
  , selectn = require('selectn');

var MILLISECONDS_IN_ONE_DAY = 24 * 60 * 60 * 1000;
var USER_DATA_VIEW_DOC = 'userData';
var VIEW = 'view';
var USER_DATA_VIEW_USER_ID_INDEX = 0;
var USER_DATA_VIEW_UTC_MONTH_INDEX = 1;
var USER_DATA_VIEW_UTC_DATE_INDEX = 2;
var USER_DATA_VIEW_MODEL_INDEX = 3;
var USER_DATA_VIEW_POSIX_TIME_INDEX = 4;

//  JavaScript months start from *zero* (while days start from 1... go figure that one out)
//  so we adjust months by adding 1 when returning previous/next days.
var CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1 = 1;

var TESTING = process.env.NODE_ENV === 'test';

var isNewUser = function(user) {

//  CouchDb keeps track of revisions and we know that there can be only one '1-' revision - the 1st one.
    return user._.rev.indexOf('1-') === 0;

};

module.exports = function(compound, User) {

    //  Store the super's findOrCreate so that we can invoke it.
    var superFindOrCreate = User.findOrCreate;

    //  Redefine findOrCreate to intercept invocations from Compound-Passport.
    User.findOrCreate = function(data, cb) {

        //  Save the user data with its facebookId.
        if(data.facebookId) {

            this.findOrCreateUserForFacebookId(data, cb);

        } else {

            debug('Invalid user data: ' + JSON.stringify(data));
            cb(new Error('Invalid user data.'));

        }

    };

//  Redefine save to always put a timestamp on the record.

    var superSave = User.prototype.save;
    User.prototype.save = function(cb) {

//  We make special allowances for life simplification during testing by always setting
//  timestamp and createdOn to 0. This way there is no postprocessing of nocks or of
//  actual tests.

        if(process.env.NODE_ENV === 'test') {

            this.timestamp = 0;
            this.createdOn = 0;

        } else {

            this.timestamp = new Date();

            //  Set createdOn if it hasn't been already set.
            if(!this.createdOn) {
                this.createdOn = this.timestamp;
            }

        }

        superSave.call(this, function(err, user) {
            if(cb) {
                cb(err, user);
            }
        });
    };

//  Update the user data if there were any relevant changes.

    function updateUserDataIfNeeded(dbUser, newData, cb) {

//  NOTE: We only check for the data that can possibly come from authentication process.

        if(dbUser.displayName !== newData.displayName
            || dbUser.email !== newData.email
            || dbUser.facebookToken !== newData.facebookToken
            || dbUser.facebookTokenSecret !== newData.facebookTokenSecret
            || dbUser.username !== newData.username
            || dbUser.birthday !== newData.birthday
            || dbUser.location !== newData.location
            || dbUser.hometown !== newData.hometown) {

            dbUser.displayName = newData.displayName;
            dbUser.email = newData.email;
            dbUser.facebookToken = newData.facebookToken;
            dbUser.facebookTokenSecret = newData.facebookTokenSecret;
            dbUser.username = newData.username;
            dbUser.birthday = newData.birthday;
            dbUser.location = newData.location;
            dbUser.hometown = newData.hometown;

            dbUser.save(cb);

        } else {

//  User data hasn't changed. We asynchronously call cb to keep the API consistently async.

            return process.nextTick(function() {
                cb(null, dbUser);
            });
        }
    }

    var isValidFacebookId = function(facebookId) {
        return !_.isEmpty(facebookId) && _.isString(facebookId);
    };

    /*jshint -W071*/
    User.findOrCreateUserForFacebookId = function(data, cb) {

        debug('findOrCreateUserForFacebookId');

        if(!isValidFacebookId(data.facebookId)) {
            return process.nextTick(function() {
                cb(new Error('invalid facebookId'));
            });
        }

//  Prepare the user doc data from the data we received. The data we
//  receive has a specific format used by Passport's Facebook strategy.

        var docData = prepareUserDocData(data);
        superFindOrCreate.call(this, {
                where: {
                    facebookId: docData.facebookId
                }
            },
            docData,
            function(err, dbUser, createdFlag) {
                if(err || !dbUser) {
                    cb(err, dbUser);
                } else {

//  We first add the data provider and then user's data. Doing it the other way around
//  wouldn't work as data provider is added only if the user is "new" - that is, it
//  has revision 1. Updating the data first would update the revision number.

                    addDataProviderIfNewUser(dbUser, function(error) {
                        if(error) {
                            return cb(error);
                        }

                        updateUserDataIfNeeded(dbUser, docData, cb);
                    });

                    if(createdFlag && !TESTING) {
                        compound.common.tracker.userSignedUp(dbUser);
                    }

                }
            });

        //  Mark the end of the main body function.
        return;

//  Convert the data we recevied from the outside.

        function prepareUserDocData(data) {

            var timestamp = new Date();

            var docData = {
                facebookId:             data.facebookId,
                username:               selectn('profile.username', data),
                facebookToken:          data.token,
                facebookTokenSecret:    data.tokenSecret,
                displayName:            selectn('profile.displayName', data),
                timezone:               data.timezone,
                utcOffset:              data.utcOffset,
                createdOn:              timestamp,
                timestamp:              timestamp
            };

            if(data.profile && data.profile._json) {
                docData.birthday = data.profile._json.birthday;
                docData.location = data.profile._json.location;
                docData.hometown = data.profile._json.hometown;
                docData.email = data.profile._json.email;
            }

//  We make special allowances for life simplification during testing by always setting
//  timestamp and createdOn to 0. This way there is no postprocessing of nocks or of
//  actual tests.

            if(TESTING) {

                docData.timestamp = 0;
                docData.createdOn = 0;

            }

            return docData;
        }

//  In case that the user is newly created we automatically add a data provider for its Facebook account
//  and start collecting their data.

        function addDataProviderIfNewUser(user, callback) {

            if(!user && !isNewUser(user)) {
                //  Invoke the callback asynchronously.
                return process.nextTick(callback);
            }

//  Add the provider object.

            var providerObjectData = {
                userId:         user._id,
                providerId:     compound.common.constants.providerId.FACEBOOK,
                providerUserId: user.facebookId,
                displayName:    user.displayName,
                providerData: {
                    token:          user.facebookToken,
                    tokenSecret:    user.facebookTokenSecret
                }
            };

            compound.models.UserDataProvider.putUserProvider(providerObjectData, function(error, provider) {

                if(!error && provider) {
                    //  In case there were no issues start collecting user's data in the background.
                    //  The background nature of this makes testing it very messy (it interfers with other
                    //  tests that may be going on) so we don't do it.
                    //  TODO: Move to message queue or database queue scheduling instead of direct scheduling.
                    if(process.env.NODE_ENV !== 'test') {
                        compound.common.scheduler.collectFacebookProviderUserInfo(provider, function(err) {
                            if(err) {
                                debug('Collection of user\'s Facebook data failed', user._id);
                            }
                        });
                    }
                }

                callback(error, provider);

            });
        }

    };
    /*jshint +W071*/

//  Generates the start key for userData view from the given parameters.

    var getUserDataStartKey = function(userId, date) {

        var month = date.getUTCMonth();
        var day = date.getUTCDate();

//  Start keys don't specify anything after the last index which is different from end keys (see end keys for details).

        return [userId, month, day];

    };

    var getUserDataEndKey = function(userId, date) {

        var month = date.getUTCMonth();
        var day = date.getUTCDate();

//  We add 1 to the day as we are seeking start of the day in the user's timezone plus 24 hours.

        return [userId, month, day + 1];

    };

    var getUserStartKey = function(userId) {

        return [userId]

    };

    var getUserEndKey = function(userId) {

        return [userId, {}];

    };

//  Make a new Date object with date and time corresponding to date preceeding the given date.

    var getPrevDay = function(date) {
        var prevDay = new Date();
        prevDay.setTime(date.getTime() - MILLISECONDS_IN_ONE_DAY);
        return prevDay;
    };

//  Make a new Date object with date and time corresponding to date following the given date.

    var getNextDay = function(date) {
        var nextDay = new Date();
        nextDay.setTime(date.getTime() + MILLISECONDS_IN_ONE_DAY);
        return nextDay;
    };

    var getMonthDayObjectFromUserDataKey = function(key) {

        return {
            month:  key[USER_DATA_VIEW_UTC_MONTH_INDEX] + CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1,
            day:    key[USER_DATA_VIEW_UTC_DATE_INDEX],
        };

    };

    User.prototype.getDayData = function(date, callback) {

//  Get all the data for the time range of a day.

        var startKey = getUserDataStartKey(this._id, date);
        var endKey = getUserDataEndKey(this._id, date);

        compound.couch.view(USER_DATA_VIEW_DOC, VIEW, {

            startkey: startKey,
            endkey: endKey,
            reduce: false,
            include_docs: true

        }, function(err, data) {
            if(err) {
                return callback(err);
            }

            if(!data || _.isEmpty(data.rows)) {
                return callback(null, []);
            }

//  We extract the docs from the response and send that back to API.

            callback(null, _.map(data.rows, function(row) {
                return row.doc;
            }));
        });

    };

//  To find the next day we get the first document after the given date.

    User.prototype.getNextUserDataDay = function(date, callback) {

//  Ensure that callback is defined.

        callback = callback || function(err) { if(err) { debug(err); } };

//  Check the input parameters.

        if(_.isUndefined(date)) {
            return process.nextTick(function() {
                callback(new Error('invalid input params'));
            });
        }

//  Get the first doc after the given date.

        var viewParams = {

            startkey: getUserDataStartKey(this._id, getNextDay(date)),
            endkey: getUserEndKey(this._id),
            limit: 1,
            reduce: false

        };

        compound.couch.view(USER_DATA_VIEW_DOC, VIEW, viewParams, function(err, docs) {

            if(err) {
                return callback(err);
            }

//  If the document doesn't exist we go to the first user's document.

            var doc = docs && !_.isEmpty(docs.rows) && docs.rows[0];
            if(!doc) {
                //  When there are no more docs we return null to signal the end of the line.
                return callback(null, null);
            }

//  The result of our query is the year, month and day of the next document.

            return callback(null, getMonthDayObjectFromUserDataKey(doc.key));
        });

    };


//  To find the previous day we get the last document before the given date.
//  This is why our view query is reversed by results.

    User.prototype.getPreviousUserDataDay = function(date, callback) {

        var that = this;

//  Ensure that callback is defined.

        callback = callback || function(err) { if(err) { debug(err); } };

//  Check the input parameters.

        if(_.isUndefined(date)) {
            return process.nextTick(function() {
                callback(new Error('invalid input params'));
            });
        }

//  Get the last doc before the given date. We get the descending order so that just the last doc is returned.
//  We also *don't* include the end as that's the given's date first doc.

        compound.couch.view(USER_DATA_VIEW_DOC, VIEW, {

//  When doing descending: true queries startkey and endkey are reversed.
//  So here we are requesting last document before the given date by requesting
//  first document in descending order that is *on* or before the previous day
//  to the given date. This took me a couple of hours of experimentations and adding bloody {}
//  to the end of the key for range.

            startkey: getUserDataEndKey(this._id, getPrevDay(date)),
            endkey: getUserStartKey(this._id),
            descending: true,
            limit: 1,
            reduce: false

        }, function(err, docs) {
            if(err) {
                return callback(err);
            }

//  If the document doesn't exist we go to the last user's document.
//  Last in this case means first of the returns because we requested the keys
//  in descending order.

            var doc = docs && !_.isEmpty(docs.rows) && docs.rows[0];
            if(!doc) {
                //  When there are no more docs we return null to signal the end of the line.
                return callback(null, null);
            }

//  The result of our query is the year, month and day of the next document.

            return callback(null, getMonthDayObjectFromUserDataKey(doc.key));
        });
    };

    /*jshint +W071*/

//  This function returns calendar data as array of { month, day, count } objects.

    User.prototype.getCalendarData = function(callback) {

//  Ensure that callback is defined.

        callback = callback || function(err) { if(err) { debug(err); } };

//  Get the reduced views.

        compound.couch.view(USER_DATA_VIEW_DOC, VIEW, {

            startkey: [this._id],
            endkey: getUserEndKey(this._id),
            reduce: true,

//  We are only interested in [user, month, date, model] part of the key so the reduce group level is +1 on model index (level).

            group_level: USER_DATA_VIEW_MODEL_INDEX + 1

        }, function(err, docs) {

            if(err) {
                return callback(err);
            }

//  When there are no results fake an empty calendar.

            docs = docs || {};
            docs.rows = docs.rows || [];

//  We reduce the data to { month, day, count, modelCount, ... } objects.

            var reduce = function (counters, item) {
                var key = item.key;
                var month = key[USER_DATA_VIEW_UTC_MONTH_INDEX] + CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1;
                var day = key[USER_DATA_VIEW_UTC_DATE_INDEX];
                var model = key[USER_DATA_VIEW_MODEL_INDEX];

                var current = _.last(counters);
                if(!current || current.month !== month || current.day !== day) {
                    current = { month: month, day: day, count: 0 };
                    counters.push(current);
                }
                current[model] = item.value;
                current.count = current.count + item.value;

                return counters;
            };

            var days = _.reduce(docs.rows, reduce, []);

            callback(null, days);

        });

    };

//  Offset for UTC timezone is 0 as the offset is always to UTC timezone itself. We use this constant when user doesn't have any set timezone.

    var UTC_TIMEZONE_OFFSET = 0;

//  Returns either user's UTC offset or, if such is not a number, returns 0 effectively treating user's data as if in UTC.

    User.prototype.getUtcOffset = function() {
        return (_.isNumber(this.utcOffset) && this.utcOffset) || UTC_TIMEZONE_OFFSET;
    };

//  This function updates selected data in the user's document only if there is was an actual change in this set of selected data.

    User.prototype.post = function(postData, callback) {

        var thisUser = this;

        callback = callback || function(error) { if(error) { console.log(error); } };

        if(!postData
            || !postData.rev) {
            return callback('Invalid POST data.');
        }

//  We don't allow updates when we know that the user's revision is out-of-date.

        if(thisUser._rev !== postData.rev) {
            return callback('Invalid rev data (' + postData.rev + ' != ' + thisUser._rev + ')');
        }

//  We don't update all the user's information on POST request. Rather, we handle each updatable property separately and only actually try to update the database if anything has really changed.

        var dirty = false;
        var timezoneChanged = false;
        if(postData.timezone
            && thisUser.timezone !== postData.timezone) {

            thisUser.timezone = postData.timezone;

            //  Timezone offset is calculated from the timezone and cached in the document.
            //  This allows us to use it directly in CouchDb views.
            thisUser.utcOffset = compound.common.timeLord.offset(thisUser.timezone);

            dirty = true;
            timezoneChanged = true;

        }

        if(dirty) {
            debug('User ', thisUser.id, ' updated. Committing to database.');
            return thisUser.save(function(error, result) {

//  Inform the invoker about the error.

                if(error) {
                    return callback(error, result);
                }

                if(timezoneChanged) {

//  Update all the user's data to the new timezone.
//  TODO: Run regular checks to ensure that user's utcOffset has been set on all its docs.
//  NOTE: To the future maintainer, if there is any other user data change that needs to be executed here I recommend that `updateUtcOffset` is refactored to `updateOnUserChanges` (or something such) and that all the work is done there with a single `callback` invoking back here.

                    return compound.common.userDataGovernor.updateUtcOffset(thisUser, callback);

                }

//  Invoke the callback when there are no other database changes needed.

                callback(error, result);

            });
        }

        callback();

    };

//  This turns the warning for the top function.
/*jshint -W071*/

};
