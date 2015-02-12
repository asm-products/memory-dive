//  Module responsible for creating or upgrading correct database schema.

'use strict';

var async = require('async')
  , debug = require('debug')('memdive::initializers::couchDbSchema')
  , fs    = require('fs')
  , _     = require('lodash');

module.exports = function (compound) {
    compound.on('ready', function() {

//  For some things we use the nano driver directly so grab it here.

        debug('Initializing the database');

        compound.couch = compound.orm._schemas[0].adapter.db;

        var db = compound.couch;

//  Worker process should initialize database. There is only single worker per cluster.
//  HACK: We make special exception when running NOCK_RECORDING as then db must also be updated.

        if (process.env.MEMORY_DIVE_WORKER || process.env.NOCK_RECORDING) {
            return deleteObsoleteDesignDocs(db, function(err) {
                if(err) {
                    return emitReady(err);
                }

                upgradeDesignDocs(db, emitReady);
            });
        } else {
            return emitReady();
        }

//  Cleans all the docs in the db except for the _design/ docs.

        function cleanDb(callback) {

            debug('Cleaning up db from all non-design documents');

            db.list(function(err, body) {
                if(err) {
                    return callback(err);
                }

                debug('Marking all non-design documents out of', body.rows.length, 'as deleted');

                var docs = [];
                return async.each(
                    body.rows,
                    function(doc, next) {
                        if(!doc) {
                            return next('doc undefined');
                        }

                        //  Don't destroy the design docs.
                        if(doc.id.indexOf('_design/') === 0) {
                            return next();
                        }

                        docs.push({
                            _id:        doc.id,
                            _rev:       doc.value.rev,
                            _deleted:   true
                        });
                        return next();
                    },
                    function(err) {
                        if(err) {
                            return callback(err);
                        }

                        debug('Bulk uploading changes to', docs.length, 'deleted docs.');

                        return db.bulk({ docs: docs }, function(err) {
                            debug('Done deleting non-design docs.');

                            callback(err);
                        });
                    }
                );
            });

        }

        function emitReady(err) {

            if(err) {
                debug('An error occurred while readying the database:', err);
                throw err.error + ': ' + err.reason;
            } else {
                debug('Database ready');
            }

//  During testing add a special clean function so that the tests
//  can clean up the db whenever needed.

            if(process.env.NODE_ENV === 'test') {
                compound.couch.cleanDb = cleanDb;
            }

            compound.emit('couchDbReady');
        }
    });
};

var deleteObsoleteDesignDocs = function(db, callback) {

    debug('Deleting obsolete design docs');
    var obsoleteDocIds = [
        '_design/panta-rhei'
    ];

    db.fetch_revs({ keys: obsoleteDocIds }, function(err, result) {
        if(err) {
            return callback(err);
        }

        var docsToDelete = [];
        var docIdsToDelete = [];
        return async.each(result.rows, function(row, next) {
                if(!row) {
                    return next('doc undefined');
                }

                if(row.value && !row.value.deleted) {

                    docsToDelete.push({
                        _id:        row.id,
                        _rev:       row.value.rev,
                        _deleted:   true
                    });

                    docIdsToDelete.push(row.id);

                }

                return next();
            },
            function(err) {
                if(err) {
                    return callback(err);
                }

                if(_.isEmpty(docsToDelete)) {
                    debug('All obsolete design docs have been deleted previously.');
                } else {
                    debug('Deleting the following docs', docIdsToDelete.join(','));
                }

                return db.bulk({ docs: docsToDelete }, callback);
            }
        );
    });

};

var upgradeDesignDocs = function(db, callback) {

    debug('Updating the design docs');

    var designDocs = _.map(fs.readdirSync('./src/server/db/design'), function(docFile) {
        //  HACK: We know all the paths, the problem is that `readdirSync` will work starting
        //      from app's root while `require` starts from __dirname of the module.
        return require('../../db/design/' + docFile);
    });

    return async.eachSeries(designDocs, function(designDoc, asyncCallback) {

        db.get(designDoc._id, null, function(err, currentDesignDoc) {

            if(err) {
                if(err.status_code !== 404) {
                    console.log('Error on db.get for', designDoc._id, ':', err);
                    return asyncCallback(err);
                }
            }

            if(!currentDesignDoc) {
                debug('Creating', designDoc._id, 'design doc.')
                db.insert(designDoc, designDoc._id, asyncCallback);
            } else {
                upgradeCurrentDesign(designDoc, currentDesignDoc, asyncCallback);
            }

        });

    }, callback);

    function upgradeCurrentDesign(designDoc, currentDesignDoc, callback) {

//  Compare the versions of the current and the new design.
//  We want to avoid overwriting the new current design
//  if possible as overwriting it invalidates views and
//  thus forces CouchDb to rebuild them.

        var upgradeDesign = currentDesignDoc.version !== designDoc.version;

        if(!upgradeDesign) {

            debug('Design doc', designDoc._id, 'is up to date (version ' + designDoc.version + ')');

            return process.nextTick(callback);

        }

        debug('Upgrading database design from version ' + currentDesignDoc.version + ' to ' + designDoc.version);

//  We will be completely replacing the current design doc so we need its revision number.

        designDoc._rev = currentDesignDoc._rev;

        db.insert(designDoc, null, callback);

    }

};
