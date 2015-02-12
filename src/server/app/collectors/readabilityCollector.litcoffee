
# readabilityCollector module

This module is responsible for collecting information from static web addresses. It's one of several planned competing and complementing modules with the same functionality.

The collection is performed in three steps:

1. URL is requested.
2. The result is passed through `readabilitySAX` module.
3. The result of that is:

* passed through `languagedetect` module to detect the language.
* passed through `inline` module to compress the HTML data (though **NOT** to inline images due to space concern)

For now we are **NOT** reading page chains as it isn't entirely clear what is the best choice here. Consider if we decide to collect everything in the page chain:

1. What happens if the chain is incorrectly interpreted? You will get a mess of a data.
2. What happens if the user references the chain from the middle? You can't count on being able to go back.
3. What happens if the user references the chain from several places? You would get duplicates if the chain is collected as a single source.

Considering all this for now we collect *only* the page that the user referenced. In the future collection of chains should be implemented per-link which will avoid duplicates. And all such non-direct reference should have a lower weight applied to it during searching (which is a whole different issue that might not be easily achievable).

## Initialization

### Used modules

    _           = require 'lodash'
    Inline      = require 'inline'
    readability = require 'readabilitySAX'
    language    = new (require 'languagedetect')
    async       = require 'async'
    debug       = (require 'debug') 'memdive::collectors::readability'
    superagent  = require 'superagent'

### Integration into CompoundJS

During initialization we perform the standard operations for all the collectors: we capture the CompoundJS app context, add this module to its set of collectors and signal the rest of the app that the collector is ready.

    app = undefined

    exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.collectors = app.collectors or {}
            app.collectors.readability = exports
            app.emit 'readabilityCollectorReady'

## Private functions

    stripHtmlTags = (html) ->
        html = html.replace /&(lt|gt);/g, (strMatch, p1) ->
            if p1 == 'lt' then '<' else '>'

        return html.replace /<\/?[^>]+(>|$)/g, ''

## Exported functions

### `collectWebPage`

`collectWebPage` will try to read the page on the given URL and transform it into a readable text. At the same time it will perform language analysis in order to improve search indexing.

`urls` - array of URLs of the pages to collect
`options` - optional options, currently not used
`callback` - obligatory function with `(error, item, next)` definition

    exports.collectWebPages = (urls, options, callback) ->

        if not callback and _.isFunction options
            callback = options
            options = {}

        return app.common.hellRaiser.invalidArgs arguments, callback if not urls or not _.isFunction callback

`processUrl` will be invoked in parallel for each url.

        processUrl = (url, eachCallback) ->

            debug 'collecting data at', url

Request the url but follow redirects.

            superagent.get(url).end (err, res) ->

                debug 'receiving web page'

                return invokeCallback err if err

Create the readability stream and write the data we received to it.

                readabilityStream = readability.createWritableStream (article) ->

                    return eachCallback article.error if article.error

Detect the language.

                    detectedLanguages = language.detect stripHtmlTags article.html, 1
                    detectedLanguage = _.first _.first detectedLanguages

Compress HTML (maybe in the future inline images)

                    inline = new Inline url, {
                        images: false
                        scripts: false
                        stylesheets: false
                    }, (err, inlineHtml) ->

Invoke the callback expecting the iteration over all the `urls`. We don't pass the original URL as we follow redirect so we pass the final location from the received response.

                        callback err, {
                            url: _.last(res.redirects) || url
                            contentType: res and res.headers and res.headers['content-type']
                            title: article.title
                            html: inlineHtml
                            language: detectedLanguage
                        }, eachCallback

                    inline.end article.html

                readabilityStream.end res.text

We process asynchronously and in parallel each url contained in the given `urls` array.

        async.each urls, processUrl, callback
