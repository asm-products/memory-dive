'use strict';

var debug = require('debug')('memdive::controllers::user');

var _ = require('lodash');
var jsend = require('express-jsend');

module.exports = UserController;

var SignedInBaseController = require('./signedInBase');

//  JavaScript months start from *zero* (while days start from 1... go figure that one out)
//  so we adjust months by adding 1 when returning previous/next days.
var CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1 = 1;

function UserController(init) {
    SignedInBaseController.call(this, init);
}

require('util').inherits(UserController, SignedInBaseController);

var sendDayData = function(c, monthDay) {

    c.req.user.getDayData(getUtcDateFromMonthDay(monthDay), function(err, data) {

        if(err) {
            return c.res.status(500).jerror(err);
        }

//  Add the previous and next links to the response data.

        var baseUrl = c.compound.common.api1UrlCreator.getCalendarMonthDayUrl(c.req.user.id, monthDay);
        var responseData = {
            month: monthDay.month,
            day: monthDay.day,
            count: data.length,
            events: data,
            prevDayUrl: baseUrl + '?prev',
            nextDayUrl: baseUrl + '?next'
        };

        c.res.status(200).jsend(responseData);

    });

};

var getMonthDayFromContext = function(c) {

    if(_.isUndefined(c.params.month)
        || _.isUndefined(c.params.day)) {
        return undefined;
    }

    //  We always decrement the month as new Date expects months in [0, 11] range (and we receive them in [1, 12] range)
    return {
        month: parseInt(c.params.month, 10),
        day:   parseInt(c.params.day, 10)
    };

};

var getUrlFromDay = function(c, day) {

    return '/user/' + c.req.user.id + '/day/' + day.month + '/' + day.day;

};

var getUrlFromDate = function(c, date) {

    return '/user/' + c.req.user.id + '/day/' + (date.getMonth() + CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1) + '/' + date.getDate();

};

//  Day controller action displays all the user data associated for the given day.
//  It also redirects the user's browser to the next/previous user day (a day that has any user data)
//  when so requested.

UserController.prototype.day = function(c) {

//  If the user request the previous day of the current day then redirect to it.

    if(!_.isUndefined(c.req.query.prev)) {
        return replyPreviusDay(c);
    }

//  If the user request the next day of the current day then redirect to it.

    if(!_.isUndefined(c.req.query.next)) {
        return replyNextDay(c);
    }

    sendDayData(c, getMonthDayFromContext(c));

};

var getUtcDateFromMonthDay = function(monthDay) {

    return new Date(Date.UTC(0, monthDay.month - CRAZY_ASS_JAVASCRIPT_MONTH_ADJUSTMENT_FACTOR_OF_1, monthDay.day));

};

var replyPreviusDay = function(c) {

    var monthDay = getMonthDayFromContext(c);

    c.req.user.getPreviousUserDataDay(getUtcDateFromMonthDay(monthDay), function(err, prevMonthDay) {

        if(err) {
            return c.redirectError(2001, err);
        }

        if(prevMonthDay === null) {
            //  TODO: Add banner information.
            return sendDayData(c, monthDay);
        }

        sendDayData(c, prevMonthDay);

    });
};

var replyNextDay = function(c) {

    var monthDay = getMonthDayFromContext(c);

    c.req.user.getNextUserDataDay(getUtcDateFromMonthDay(monthDay), function(err, nextMonthDay) {

        if(err) {
            return c.redirectError(2002, err);
        }

        if(nextMonthDay === null) {
            //  TODO: Add banner information.
            return sendDayData(c, monthDay);
        }

        sendDayData(c, nextMonthDay);

    });

};

UserController.prototype.__developmentOnlyCollectUserDataOnDemand = function(c) {

    c.compound.common.scheduler.refreshUserInfo(c.req.user, function(err) {
        if(err) {
            debug('Refreshing of user data failed', err);
        }
    });

    c.res.status(200).jsend();

};

UserController.prototype.__developmentOnlySendDailyEmailsOnDemand = function(c) {

    var user = c.req.user;

    c.compound.common.emailSender.sendDailyMemoriesEmail(user, function(responses) {
        }, function(err) {
            console.log('Error sending daily email to', user && user.email, ':', err);
        });

    c.res.status(200).jsend();

};

UserController.prototype.__developmentOnlyBackupUserDataOnDemand = function(c) {

    var user = c.req.user;

    c.compound.common.scheduler.backupUserDataToAllProviders(user, function(err, result) {
            if(err) {
                console.log('Error backing up data for', user && user.email, ':', err);
            }
        });

    c.res.status(200).jsend();

};

UserController.prototype.calendar = function(c) {

    c.req.user.getCalendarData(function(err, data) {

        if(err) {
            c.res.status(500).jerror(err);
        } else {

//  Our API is self-descriptive so we include the days API URLs into the response itself.
//  We modified it in-place as this data will be descarded after being returned.

            var userId = c.req.user.id;
            _.each(data, function(datum) {
                datum.url = c.compound.common.api1UrlCreator.getCalendarMonthDayUrl(userId, datum);
            });

            c.res.status(200).jsend(data);
        }

    });

};

//  Updates selected data in the user's document.

UserController.prototype.post = function(c) {

    c.req.user.post(c.req.body, function(err) {

        if(err) {

            c.res.status(500).jerror(err);

        } else {

            //  Send back the new revision number.
            c.res.status(200).jsend({ rev: c.req.user._rev });

        }

    });

};
