
//  All views are separated, each in its own design doc.
//  This limits doc reindexing only to those designs that actually change.

var designDoc = {
    _id: '_design/allUserData',
    //  *********************************************************************************
    //
    //
    //  Change the design version every time anything in the design document has changed.
    //
    //
    //  *********************************************************************************
    version: '2014-07-27-0002',
    views: {},
    lists: {},
    shows: {},
    indexes: {}
};

//  This view indexes *ALL* the user data that we have in the database
//  (collected from providers, event created in Memory Dive, etc.)

designDoc.views.view = {

    map: function(doc) {

        if(doc.userId) {
            emit(doc.userId);
            return;
        }

//  User model doesn't have userId but it's still user data (obviously).

        if(doc.model === 'User') {
            emit(doc._id);
            return;
        }

    },

    reduce: '_count'

};

module.exports = designDoc;
