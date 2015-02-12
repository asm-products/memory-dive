
//  All views are separated, each in its own design doc.
//  This limits doc reindexing only to those designs that actually change.

var designDoc = {
    _id: '_design/objectHistoricMetadata',
    //  *********************************************************************************
    //
    //
    //  Change the design version every time anything in the design document has changed.
    //
    //
    //  *********************************************************************************
    version: '2014-05-18-0131',
    views: {},
    lists: {},
    shows: {},
    indexes: {}
};

designDoc.views.view = {

    map: function(doc) {

        if(doc && doc.model === 'ObjectMetadata') {
            emit([doc.objectId, doc.metadataId, doc.createdOn], doc.metadata);
        }

    }

};

module.exports = designDoc;
