'use strict';

var _     = require('lodash')
  , debug = require('debug')('memdive::collectors::twitter')
  , async = require('async')
  , twit  = require('twit');

//  We are working with Facebook API and it uses non-camel case identifiers
//  so we disable the warning W106.
/*jshint -W106*/

//  Twitter allows 180 API calls to statuses endpoint per 15 minutes.
var TWITTER_STATUSES_RATE_LIMIT = 180;
var TWITTER_RATE_LIMIT_RESET_IN_MINUTE = 15;
//  Number of status requests per minute allowed by Twitter.
var TWITTER_ALLOWES_STATUSES_PER_MINUTE = TWITTER_STATUSES_RATE_LIMIT / TWITTER_RATE_LIMIT_RESET_IN_MINUTE;
//  We increase the delays by 1% to avoid being too close to Twitter's rate limit.
var DELAY_FUDGE_FACTOR = 1.01;
var MILLISECONDS_IN_MINUTE = 60 * 1000;
var TWITTER_RATE_LIMIT_AVOIDANCE_DELAY_IN_MILLISECONDS = DELAY_FUDGE_FACTOR * MILLISECONDS_IN_MINUTE / TWITTER_ALLOWES_STATUSES_PER_MINUTE;

var app;

exports.init = function(compound) {

    compound.on('ready', function(compoundApp) {
        app = compoundApp;

        app.collectors = app.collectors || {};
        app.collectors.twitter = exports;
        app.emit('twitterCollectorReady');
    });

};

//  Specialized error returned from Twitter calls.
function TwitterError(message) {
    Error.call(this);
    this.message = message;
}

require('util').inherits(TwitterError, Error);

exports.collectUserStatuses = function(provider, params, callback) {

    if(!provider
        || !params
        || !callback) {
        return new TwitterError('Invalid input params');
    }

    if(!provider.userId
        || provider.providerId !== app.common.constants.providerId.TWITTER
        || !provider.providerUserId
        || !provider.providerData
        || !provider.providerData.token
        || !provider.providerData.tokenSecret) {
        return process.nextTick(function() {
            callback(new TwitterError('Provider data not validly associated with Twitter'));
        });
    }

    var twitter = new twit({
        consumer_key:           params.twitterConsumerKey,
        consumer_secret:        params.twitterConsumerSecret,
        access_token:           provider.providerData.token,
        access_token_secret:    provider.providerData.tokenSecret,
    });

    var currentMaxId;

    return readData();

    function readData(err, reply) {

//  When err, reply and currentMaxId are all falsy then it's the first invocation.
//  When err and reply are falsy then it's a request for a new API call with max_id as limiting factor.

        if(err) {
            return callback(err);
        }

        if(reply) {

            if(!_.isArray(reply)) {
                return callback(new TwitterError('Reply is not an array'));
            }

            if(_.isEmpty(reply)) {

//  When the reply is empty we know we have reached the end of user's statuses data.

                return callback();
            }

//  We asynchronously but serially iterate over all the items in the reply.
//  The client invoked through callback is required to invoke next() for the
//  next iteration to kick in.

            var maxId;

            return async.eachSeries(
                reply,
                function(item, next) {

                    if(!item) {
                        return next(new TwitterError('Tweet undefined'));
                    }

//  Skip the item that has the same ID as the current max ID as that item has already been processed.
//  The problem here is that we cannot rely on maxId-1 on Twitter API invocations as IDs can be too big to have sufficiently precise substraction. Hence we know that each call to API will bring a duplicate item (the last item from the previous call) so we eliminate those.

                    if(item.id === currentMaxId) {
                        return next();
                    }

//  Store the currentMaxId to be used in the next API call.

                    maxId = item.id;

//  Allow the client to process the item.

                    callback(err, item, next);

                },

//  When iteration finishes we either continue on to the next API call or stop due to an error.

                function(err) {
                    if(err) {
                        return callback(err);
                    }

//  maxId has to be truthy as otherwise we will loop forever (see the conditions at the top of the function)
//  We simply quit the iteration without indicating any error as there might not *be* any error
//  (e.g. maxId === 0 isn't an error but it's simply an end of iteration.)

                    if(!maxId) {
                        return callback();
                    }

//  To avoid hitting Twitter's rate delay we introduce a delay between each new API call.

                    setTimeout(function() {

//  Read the data from the last invocation's maxId.

                        currentMaxId = maxId;
                        readData();

                    }, params.suppressThrottling ? 0 : TWITTER_RATE_LIMIT_AVOIDANCE_DELAY_IN_MILLISECONDS);

                }

            );

        }

//  Invoke the twitter API with the max count of 200 and inclusion of re-tweets.

        debug('calling Twitter API statuses/user_timeline');

        twitter.get('statuses/user_timeline', {
            user_id:        provider.providerUserId,
            count:          200,
            include_rts:    1,
            max_id:         currentMaxId
        }, readData);

    }

};
