
# FrugalCouch

FrugalCouch is a module written for minimization of requests passed toward CouchDb. It uses a combination of caching and bulk loading. It is *not* a general purpose module (that is, it doesn't work for all types of scenarios) but only for cases where the data has low or non-existing update rate or where it can be safely overwritten.

It works by a combination of intercepting HTTP requests toward configured CouchDb stores and a public API for direct requests. Interception avoids writing specialized modules to replace different CouchDb drivers (e.g. replacign nano, yacw, etc. each in its parents module quickly explodes the number of modules that have to be forked).

FrugalCouch uses a forked and modified version of nano for passing requests toward CouchDb.

Intercepting

The module exports the following methods:
 1. putDoc: this method will put the document on the CouchDb overwritting any doc with the same key if it exists.

    exports.putDoc = (doc) ->

    docCache = []
    bulkCache = []

    cacheDoc = (doc) ->
        return if not doc

        docCache.push doc
        if docCache >= CACHE_LIMIT
