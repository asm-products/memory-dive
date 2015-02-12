
//  All views are separated, each in its own design doc.
//  This limits doc reindexing only to those designs that actually change.

var designDoc = {
    _id: '_design/userDataUtcOffset',
    //  *********************************************************************************
    //
    //
    //  Change the design version every time anything in the design document has changed.
    //
    //
    //  *********************************************************************************
    version: '2014-06-09-0132',
    views: {},
    lists: {},
    shows: {},
    indexes: {}
};

//  This view maps data doc's user ID with its UTC offset. It is used to quickly check if the UTC offsets of all the user's documents are equal. At reduce 'exact' level it should *always* return just one doc per user. If it returns more than one doc then user's data needs to be synchronized with the user's UTC offset.

designDoc.views.view = {

    map: function(doc) {

        switch(doc.model) {
        case 'FacebookObject':
        case 'TwitterObject':
        case 'DropboxObject':
        case 'EvernoteObject':
        case 'SlackObject':
        case 'FoursquareObject':
            emit([doc.userId, doc.utcOffset]);
            break;
        }

    },

    reduce: '_count'

};

module.exports = designDoc;
