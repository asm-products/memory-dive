
//  All views are separated, each in its own design doc.
//  This limits doc reindexing only to those designs that actually change.

var designDoc = {
    _id: '_design/userText',
    //  *********************************************************************************
    //
    //
    //  Change the design version every time anything in the design document has changed.
    //
    //
    //  *********************************************************************************
    version: '2014-06-09-0133',
    views: {},
    lists: {},
    shows: {},
    indexes: {}
};

//  This is Cloudant-only search index.

designDoc.indexes.index = {

    analyzer: 'standard',

    index: function(doc) {

        var extra = doc.extra;

        switch(doc.model) {
        case 'FacebookObject':
            index('userId', doc.userId);

            switch(doc.type) {
            case 'post':
                switch(extra.type) {
                case 'link':
                    if(extra.message) {
                        index('text', extra.message);
                    }
                    break;
                case 'status':
                    if(extra.message) {
                        index('text', extra.message);
                    }
                    if(extra.story) {
                        index('text', extra.story);
                    }
                    break;
                default:
                    break;
                }
                break;
            case 'photo':
            case 'video':
                if(doc.name) {
                    index('text', doc.name);
                }
                break;
            case 'note':
                if(extra) {
                    if(extra.subject) {
                        index('text', extra.subject);
                    }
                    if(extra.messageHtml) {
                        index('text', extra.messageHtml);
                    }
                }
                break;
            default:
                break;
            }
            break;
        case 'TwitterObject':
            index('userId', doc.userId);
            if(doc.text) {
                index('text', doc.text);
            }
            break;
        case 'DropboxObject':
            //  Nothing for now.
            break;
        case 'EvernoteObject':
            index('userId', doc.userId);
            if(extra) {
                if(extra.title) {
                    index('text', extra.title);
                }
                if(extra.content) {
                    index('text', extra.content);
                }
            }
            break;
        case 'SlackObject':
            index('userId', doc.userId);
            index('text', doc.text);
            break;
        case 'FoursquareObject':
            index('userId', doc.userId);
            index('text', doc.text);
            break;
        default:
            break;
        }
    }

};

module.exports = designDoc;
