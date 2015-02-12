
# CouchDb utils

This module exports utilities for working with CouchDb.

For logging and other tasks we use several external modules.

    _       = require 'lodash'
    debug   = (require 'debug') 'memdive::common::couchDbUtils'

## `overwriteBulk`

### A method for bulk updating of given documents even when their revision values are out of date.

Bulk updating documents have two significant advantages over updating them one by one:

1.It's much faster as it requires only two trips to CouchDb for all the docs vs. two trips for each doc (one trip to try to update and if that fails then a new trip with corrected revision value)
2.It's much cheaper if used on DaaS like Cloudant which charge the same for bulk requests and non-bulk requests (so if you have 10,000 docs that you need to update you'll be charged for 2 requests and not for 20,000 requests)

Bulk updating shouldn't be used always unless you are absolutely certain that nothing else is updating your database. It can be very useful even in multi-client databases as some types of documents may considered to be stable and depending only on external values (e.g. importing Facebook Graph data)

`overwriteBulk` method accepts three parameters:

1.`database`: database nano object (or an object with same semantics) used to access the database
2.`docs`: an array of documents that need to be bulk-updated
3.`callback`: function accepting err parameter to be invoked when the update finishes or in the case of any error

    exports.overwriteBulk = (database, docs, callback) ->

        return process.nextTick callback if not _.isArray docs or _.isEmpty docs

We save the documents directly through CouchDb driver, not through JugglingDb adapter, as it lacks bulk uploading features. Since CouchDb doesn't support bulk updating without _rev we first retreive all the revision numbers of all given docs. That allows us to update the _rev values of the docs we are supposed to update and only then do we bulk upload the docs.

        debug 'Bulk inserting/updating', docs.length, 'docs'

Construct the map of doc ids with doc objects so that we can both access just the list of doc ids as well as be able to later update the revisions of docs in `O(n log n)`.

        idDocsMap = {}
        _.each docs, (doc) ->
            idDocsMap[doc._id] = doc;

Query the database for the revisions of all the docs. Once we have the revisions we will update the docs and then bulk upload them.

        debug 'Fetching doc revisions'

        return database.fetch_revs { keys: Object.keys idDocsMap }, (err, revisions) ->
            return callback err if err
            return callback new Error 'Invalid document revisions returned.' unless revisions

Update the revisions of the documents with the revision values we got from the server. The conditions to update the revision value are:

1. Row object exists and has both value and id properties.
2. The document with the same id already exists in the db (even if it's deleted as CouchDb keeps *all* docs forever).

--

            debug 'Updating docs with correct revisions'

            insertCount = 0
            updateCount = 0
            deletedCount = 0
            _.each revisions.rows, (row) ->

We update the doc if and only if everything is correct (doc id exists among our docs, rev was correctly returned from the server, doc isn't deleted on the server, etc.)

                return debug 'Bad revision item received' unless row
                if row.error
                    if row.error == 'not_found'
                        ++insertCount
                    else
                        debug 'Error received', row.error
                    return
                return debug 'Bad revision value received' unless row.value and row.value.rev
                doc = idDocsMap[row.id]
                return debug 'Bad document id received', row.id unless doc

If the document with the same id already existed but was deleted then CouchDb will expect from us to *not* pass revision number. But if it exists right now (it hasn't been deleted) then we have to correctly pass its revision number.

                if row.value.deleted
                    delete doc._rev
                    ++deletedCount
                else
                    doc._rev = row.value.rev
                    ++updateCount

After the document revs have been updated, we bulk load them and pass on the results.

            debug 'Spawning', insertCount, 'docs'
            debug 'Morphing', updateCount, 'docs'
            debug 'Resuscitating', deletedCount, 'docs'

            database.bulk { docs: docs }, callback

## `partialUpdateBulk`

### A method for partially updating the documents with the given IDs.

CouchDb allows partial server-side modification of documents through its update handler feature. However, this feature doesn't work for arrays of documents and is thus too slow for massive document updates.

The alternative is to retrieve all the documents, apply the modification function to them and then bulk upload them. This is what `partialUpdateBulk` does.

    exports.partialUpdateBulk = (database, docIds, partialUpdater, callback) ->

        debug 'Partial bulk updating', docIds.length, 'docs'

        return process.nextTick callback if not _.isArray docs or _.isEmpty docs

        return database.fetch { keys: docIds }, (err, docs) ->
            return callback err if err
            return callback new Error 'Invalid documents returned.' if _.isEmpty docs

            _.each docs, (doc) ->
                partialUpdater doc

            database.bulk { docs: docs }, callback

## `iterateView`

### A method for iterating over a CouchDb view.

This function accepts the following parameters:

1.`database`    -   `nano` database object.
2.`designDoc`   -   the name of the design document in which the view is to be found.
3.`viewName`    -   the name of the view which will be queried.
4.`options`     -   standard CouchDb options like `startkey` and `endkey`. It also holds the number of documents in each desired iteration in its `limit` property. If it doesn't then the default batch size is 100 documents (completely arbitrary number). One property that this function ignores is `skip` as it's needed to perform correct and optimal iterations.
5.`iterator`    -   function accepting `err`, `docs` and `next` parameters:

-`err`  -   error value in case of any error, falsy otherwise.
-`docs` -   the array of documents in the current iteration.
-`next` -   the function to be invoked when the next iteration should be performed.

    exports.iterateView = (database, designDoc, viewName, options, iterator) ->

Create a clone of the given `options` so that we don't change them during iteration.

        options = options || {}
        options = _.clone options
        options.skip = 0
        options.limit = options.limit or 100

`nextIteration` function performs all the work of querying the view, checking the results and invoking the `iterator` function.

        nextIteration = () ->
            database.view designDoc, viewName, options, (err, data) ->
                return iterator err if err
                return iterator null, [] if not data or _.isEmpty(data.rows)

Increment the skip count depending on the amount of data we got in this iteration.

                options.skip = options.skip + data.rows.length

Indirect recursion call. This will invoke the `iterator` function which in turn will invoke `nextIteration` itself when it finishes processing the current batch.

                iterator null, data.rows, nextIteration

Start iteration by invoking `nextIteration` for the first time.

        nextIteration()
