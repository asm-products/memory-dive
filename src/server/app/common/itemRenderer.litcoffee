
# Rendering items to HTML

This module is responsible for rendering item documents to HTML. Since most of the rendeding is very easy `lodash` templating engine is used. For now the items are rendered on the server but there is no reason to compile this into JS and render it on the client instead.

    _       = require 'lodash'
    moment  = require 'moment'

The module is integrated into CompoundJS application.

    debug = (require 'debug') 'memdive::common::itemRenderer'

    app = undefined

    module.exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.common = app.common or {}
            app.common.itemRenderer = exports
            app.emit 'itemRendererReady'

The complete module is abstracted behind a single exported function. This function accepts the document to render and dispatches it to the corresponding renderer function. It also handles unknown types of documents. In case of any exception it still returns a valid HTML with the text of the exception.

    render = (doc) ->
        html = undefined
        try
            if not doc or not doc.model
                html = renderUnknownDoc doc
            else
                switch doc.model
                    when 'FacebookObject' then html = renderFacebookObject doc
                    when 'TwitterObject' then html = renderTwitterObject doc
                    when 'DropboxObject' then html = renderDropboxObject doc
                    when 'EvernoteObject' then html = renderEvernoteObject doc
                    else html = renderUnknownDoc doc
        catch error
            console.log 'Item renderer threw an exception: ', error
            html = exceptionTemplate { error: error }

        html += timeTemplate {
            time: moment((doc and (doc.createdTime + (doc.utcOffset or 0))) or 0).utc().format 'HH:mm:ss'
        }
        return html

    exports.render = render

## Templates

All HTML rendering is done through `lodash` templating engine.

    unknownObjectTemplate = _.template '<h5>Unknown item (model <%= model %>, ID <%= modelId %>)</h5>'
    exceptionTemplate = _.template '<h5>Exception thrown: <%= error %></h5>'
    invalidObjectTemplate = _.template '<h5>Invalid object (model <%= model %>, ID <%= modelId %>, details <%= details %>)</h5>'
    imgTemplate = _.template '<img src="<%- source %>" class="img-responsive"/>'
    embedHtmlTemplate = _.template '<div><%= embedHtml %></div>'
    statusTemplate = _.template '<h5><%- status %></h5>'
    timeTemplate = _.template '<h6><%= time %></h6>'
    facebookLinkTemplate = _.template '<h5><a href="<%- link %>" target="_blank"><img src="<%- picture %>"/></a><%- message %></h5>'
    dropboxImg = _.template '<img id="dropbox-<%- path %>"/>'

## Rendering unknown items

There are two ways to handle unknown or invalid items:

1.  Ignore them simply not displaying them
2.  Display a stand-in item that allows the user to get some data out of the system and conceivably request support.

We display a stand-in item as that both:

a) Allows the user to actually see that the data exist though it's not understood by the system and

b) Allows us to keep consistent statistics where the number of diplayed items *always* matches the number of items that actually exist in the system.

    renderUnknownDoc = (doc) ->
        doc = doc or {}
        doc.modelId = 'unknown' if not doc.modelId
        doc.model = 'unknown' if not doc.model
        console.log 'Unknown object rendered:', doc.model, doc.modelId
        return unknownObjectTemplate doc

    renderInvalidObject = (model, id, details) ->
        console.log 'Invalid object rendered:', model, id, details
        return invalidObjectTemplate {
            model: model
            modelId: id
            details: details
        }

## Rendering helpers

We render valid URLs in texts as <a href="url" target="_blank">url</a>. This allows users to click on these URLs and open them in a new browser window.

    validUrlsRegex = /(\b(https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|!:,.;]*[\-A-Z0-9+&@#\/%=~_|])/ig

    renderValidUrls = (text) ->
        return text.replace validUrlsRegex, '<a href="$1" target="_blank">$1</a>'

## Rendering FacebookObject document

FacebookObject has many different subtypes that need to be accounted for. Each of the subtypes has its own rendering function with one main function doing the dispatching.

    renderFacebookObject = (doc) ->
        return renderInvalidFacebookObject doc if not doc.type

        switch doc.type
            when 'photo' then return renderFacebookObjectPhoto doc
            when 'video' then return renderFacebookObjectVideo doc
            when 'post' then return renderFacebookObjectPost doc
            else renderInvalidFacebookObject doc

    renderInvalidFacebookObject = (doc) ->
        return renderInvalidObject doc.model, doc.modelId, 'type ' + doc.type

    renderFacebookObjectPhoto = (doc) ->
        return renderInvalidFacebookObject doc if not doc.source
        return imgTemplate doc

    renderFacebookObjectVideo = (doc) ->
        return renderInvalidFacebookObject doc if not doc.extra or not doc.extra.embedHtml
        return embedHtmlTemplate { embedHtml: doc.extra.embedHtml }

    renderFacebookObjectPost = (doc) ->
        return renderInvalidFacebookObjectPost doc if not doc.extra or not doc.extra.type
        switch doc.extra.type
            when 'link' then renderFacebookObjectPostLink doc
            when 'status' then renderFacebookObjectPostStatus doc
            when 'photo' then renderFacebookObjectPostPhoto doc
            else return renderInvalidFacebookObjectPost doc

    renderInvalidFacebookObjectPost = (doc) ->
        return renderInvalidObject doc.model, doc.modelId, 'type ' + doc.type + '.' + (doc.extra and doc.extra.type)

    renderFacebookObjectPostLink = (doc) ->
        return renderInvalidFacebookObjectPost doc if not doc.extra.link or not doc.extra.message
        return facebookLinkTemplate {
            link: doc.extra.link
            message: doc.extra.message
            picture: doc.picture || ''
        }

    renderFacebookObjectPostStatus = (doc) ->
        return renderInvalidFacebookObjectPost doc if not doc.extra.message and not doc.extra.story
        return renderValidUrls statusTemplate { status: doc.extra.message or doc.extra.story }

    renderFacebookObjectPostPhoto = (doc) ->
        return renderInvalidFacebookObjectPost doc if not doc.picture
        return imgTemplate { source: doc.picture }

## Rendering TwitterObject document

Right now we only support TwitterObject with status type (aka tweets).

    renderTwitterObject = (doc) ->
        return renderInvalidTwitterObject doc if not doc.type

        switch doc.type
            when 'status' then return renderTwitterObjectStatus doc
            else renderInvalidTwitterObject doc

    renderInvalidTwitterObject = (doc) ->
        return renderInvalidObject doc.model, doc.modelId, doc.type

    renderTwitterObjectStatus = (doc) ->
        return renderInvalidTwitterObject doc if not doc.text
        html = '<h5>'
        if doc.extra and doc.extra.retweeted
            html += 'RT'
            if doc.extra.by
                html += ' <a href="https://twitter.com/' + doc.extra.by + '" target="_blank">@' + doc.extra.by + '</a>'
            html += ': '
        html += renderTwitterHandles(renderValidUrls(doc.text)) + '</h5>'
        return html

    linkToTweet = (doc) ->
        link = '//tweeter.com/'
        if value.extra and value.extra.by
            link += value.extra.by + '/'
        link += value.modelId
        return link

We render twitter handles in tweets as links to Twitter users.

    twitterHandleRegex = /@(\w+)/ig

    renderTwitterHandles = (text) ->
        return text.replace twitterHandleRegex, '<a href="https://twitter.com/$1" target="_blank">@$1</a>'

## Rendering DropboxObject document

Rendering Dropbox objects is done in two phases:

1. Server-side outputs the file system paths relative to Dropbox root as src for images
2. A JS script running in the browser takes these paths and converts them to correct URLs

This is necessary as Dropbox requires authentication on the client-side to access permanently available URLs.

    renderDropboxObject = (doc) ->
        return renderInvalidObject doc.model, doc.modelId, doc.type if not doc.path
        return dropboxImg { path: doc.path }

## Rendering EvernoteObject document

TODO: Implement this.

    renderEvernoteObject = (doc) ->
        return renderUnknownDoc doc
