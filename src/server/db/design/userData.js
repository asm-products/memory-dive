
//  All views are separated, each in its own design doc.
//  This limits doc reindexing only to those designs that actually change.

var designDoc = {
    _id: '_design/userData',
    //  *********************************************************************************
    //
    //
    //  Change the design version every time anything in the design document has changed.
    //
    //
    //  *********************************************************************************
    version: '2014-06-09-0148',
    views: {},
    lists: {},
    shows: {},
    indexes: {}
};

//  This view indexes user's data per month, day and the year.

designDoc.views.view = {

    map: function(doc) {

        var model = doc && doc.model;

        if(!model
            || (model !== 'FacebookObject'
                && model !== 'TwitterObject'
                && model !== 'DropboxObject'
                && model !== 'EvernoteObject'
                && model !== 'SlackObject'
                && model !== 'FoursquareObject')) {
            return;
        }

//  Maybe there are some docs that will pass through without createdTime or createdTime
//  as string or other non-number data. Those we treat as if they were created on Epoch start time (zero)
//  This makes it somewhat clear for users that there is something wrong with it but still shows the item.

        var createdTime = (typeof(doc.createdTime) === 'number' && doc.createdTime);
        if(!createdTime) {

//  When createdTime isn't available we can try using updated time.

            var updatedTime = (typeof(doc.updatedTime) === 'number' && doc.updatedTime) || 0;
            createdTime = updatedTime;
        }

//  When utcOffset doesn't exist we assume UTC timezome (zero offset).

        var utcOffset = (typeof(doc.utcOffset) === 'number' && doc.utcOffset) || 0;

//  We will use offset created time to generate view's keys.
//  This offseting fakes the time in which the event occurred so that user's get month/day
//  of *their* configured timezone and not UTC. There are no other alternatives to doing this
//  in CouchDb short of importing the entire timezone database and using it in this funciton.
//  Note that we still send *real* UTC createdTime in the view's value. It's only the key time
//  that gets faked (offset).

        var offsetCreatedTime = createdTime + utcOffset;

        var keyDate = new Date(offsetCreatedTime);

//  The key for user data consists of userId, user's timezone month/day (faked with offseting compared to UTC) of the datum and the exact POSIX epoch of the datum.
//  We need these keys because of the following:
//      1.  userId - for obviously we need to be able to discern a particular user data among all the data that we have.
//      2.  User's timezone month/day as we keep all the time data in faked UTC to present it easily to our users.
//      3.  Documents model so that we can reduce them for counting purposes. The problem is that custom reduce functions are *very* slow in CouchDb so for our purposes it's better to do reduce on the client.
//      4.  Finally, for items that have the same month/date/model we need to be able to correctly sort them and the POSIX epoch time (ambiguous as it may be due to the issue of leap seconds) is the final arbitrer.

        var key = [doc.userId,

//  Note that even though getMonth() returns [0-11] we leave it as is
//  as otherwise we would have to adapt all the client calls to use the +1 on month.

            keyDate.getUTCMonth(),
            keyDate.getUTCDate(),

//  Include the model so that we can use it in reduce phase.

            model,

//  We add the get time to get docs within the same day sorted by the time and not jumbled up.

            keyDate.getTime()];

//  We only emit the key. Actual data is retrieved with `include_docs` option.

        emit(key);

    },

    reduce: '_count'

};

module.exports = designDoc;
