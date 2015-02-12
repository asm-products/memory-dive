## Rendering items to HTML
# This directive is responsible for rendering item documents to HTML. Since most of the rendeding is very easy `lodash` templating engine is used.

angular.module('memoryDiveApp').directive 'mofsItemRenderer', ['$log', '$http', '$q', '$cacheFactory', '$timeout', ($log, $http, $q, $cacheFactory, $timeout) ->

    link = (scope, elem, attrs) ->
        doc = scope.event
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
                    when 'SlackObject' then html = renderSlackObject doc
                    when 'FoursquareObject' then html = renderFoursquareObject doc
                    else html = renderUnknownDoc doc

        catch error
            $log.info 'Item renderer threw an exception: ', error
            html = exceptionTemplate { error: error }

        dateFormat = attrs.dateFormat or 'HH:mm:ss'
        html += timeTemplate {
            time: moment((doc and (doc.createdTime + (doc.utcOffset or 0))) or 0).utc().format dateFormat
        }

        html += '<br>'

        elem.append html

    ## Templates

    unknownObjectTemplate = _.template '<h5>Unknown item (model <%= model %>, ID <%= id %>)</h5>'
    exceptionTemplate = _.template '<h5>Exception thrown: <%= error %></h5>'
    invalidObjectTemplate = _.template '<h5>Invalid object (model <%= model %>, ID <%= id %>, details <%= details %>)</h5>'
    imgTemplate = _.template '<img src="<%- source %>" class="img-responsive"/>'
    embedHtmlTemplate = _.template '<div class="flex-video widescreen"><%= embedHtml %></div>'
    statusTemplate = _.template '<h5><%- status %></h5>'
    timeTemplate = _.template '<h6><%= time %></h6>'
    facebookImgTemplate = _.template '<% if (link) { %><a href="<%- link %>" target="_blank"><% } %><img src="<%- source %>" class="img-responsive"/><% if (link) { %></a><% } %><% if (name) { %><h5><%- name %></h5><% } %>'
    facebookLinkTemplate = _.template '<h5><a href="<%- link %>" target="_blank"><img src="<%- picture %>"/></a><br><br><%- message %></h5>'
    facebookNoteTemplate = _.template '<div><%= subject %></div><h6><%= messageHtml %></h6>'
    facebookLikeSourceTemplate = _.template '<div><%= name %></div><img src="<%- source %>" class="img-responsive"/>'
    facebookStatusTemplate = _.template '<h6><%= message %></h6>'
    evernoteTemplate = _.template '<div class="flex-video widescreen"><%= content %></div><h5><%= title %></h5>'
    slackTemplate = _.template '<div><%= text %></div><h6><%= channel %></h6>'
    foursquareTemplate = _.template '<div><%= text %></div><h6><%= venue %></h6>'

    ## Rendering unknown items

    # There are two ways to handle unknown or invalid items:
    #
    # 1.  Ignore them simply not displaying them
    # 2.  Display a stand-in item that allows the user to get some data out of the system and conceivably request support.
    #
    # We display a stand-in item as that both:
    #
    # a) Allows the user to actually see that the data exist though it's not understood by the system and
    # b) Allows us to keep consistent statistics where the number of diplayed items *always* matches the number of items that actually exist in the system.

    renderUnknownDoc = (doc) ->
        doc = doc or {}
        doc.id = 'unknown' if not doc.id
        doc.modelId = 'unknown' if not doc.modelId
        doc.model = 'unknown' if not doc.model
        $log.info 'Unknown object rendered:', doc.id, doc.model, doc.modelId
        return unknownObjectTemplate doc

    renderInvalidObject = (id, model, modelId, details) ->
        $log.info 'Invalid object rendered:', id, model, modelId, details
        return invalidObjectTemplate {
            id: id
            model: model
            modelId: modelId
            details: details
        }

    ## Rendering helpers
    # We render valid URLs in texts as <a href="url" target="_blank">url</a>. This allows users to click on these URLs and open them in a new browser window.

    validUrlsRegex = /(\b(https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|!:,.;]*[\-A-Z0-9+&@#\/%=~_|])/ig

    renderValidUrls = (text) ->
        return text.replace validUrlsRegex, '<a href="$1" target="_blank">$1</a>'

    ## Rendering FacebookObject document
    # FacebookObject has many different subtypes that need to be accounted for. Each of the subtypes has its own rendering function with one main function doing the dispatching.

    renderFacebookObject = (doc) ->
        return renderInvalidFacebookObject doc if not doc.type

        switch doc.type
            when 'photo' then return renderFacebookObjectPhoto doc
            when 'video' then return renderFacebookObjectVideo doc
            when 'post' then return renderFacebookObjectPost doc
            when 'note' then return renderFacebookObjectNote doc
            when 'like' then return renderFacebookObjectLike doc
            when 'status' then return renderFacebookObjectStatus doc
            else renderInvalidFacebookObject doc

    renderInvalidFacebookObject = (doc) ->
        return renderInvalidObject doc.id, doc.model, doc.modelId, 'type ' + doc.type

    renderFacebookObjectPhoto = (doc) ->
        return renderInvalidFacebookObject doc if not doc.source
        return facebookImgTemplate {
            source: doc.source
            name: doc.name or null
            link: doc.link or null
        }

    renderFacebookObjectVideo = (doc) ->
        return renderInvalidFacebookObject doc if not doc.extra or not doc.extra.embedHtml
        return embedHtmlTemplate { embedHtml: doc.extra.embedHtml }

    renderFacebookObjectNote = (doc) ->
        return renderInvalidFacebookObject doc if not doc.extra
        return facebookNoteTemplate doc.extra

    renderFacebookObjectLike = (doc) ->
        return renderInvalidFacebookObject doc if not doc.extra
        return facebookLikeSourceTemplate {
            source: doc.extra?.cover?.source
            name: doc.name
        }

    renderFacebookObjectStatus = (doc) ->
        return renderInvalidFacebookObject doc if not doc.extra
        return facebookStatusTemplate doc.extra

    renderFacebookObjectPost = (doc) ->
        return renderInvalidFacebookObjectPost doc if not doc.extra or not doc.extra.type
        switch doc.extra.type
            when 'link' then renderFacebookObjectPostLink doc
            when 'status' then renderFacebookObjectPostStatus doc
            when 'photo' then renderFacebookObjectPostPhoto doc
            else return renderInvalidFacebookObjectPost doc

    renderInvalidFacebookObjectPost = (doc) ->
        return renderInvalidObject doc.id, doc.model, doc.modelId, 'type ' + doc.type + '.' + (doc.extra and doc.extra.type)

    renderFacebookObjectPostLink = (doc) ->
        return renderInvalidFacebookObjectPost doc if not doc.extra.link and (not doc.extra.story or not doc.extra.message)
        return facebookLinkTemplate {
            link: doc.extra.link
            message: doc.extra.message or doc.extra.story or doc.extra.description
            picture: doc.picture or ''
        }

    renderFacebookObjectPostStatus = (doc) ->
        return renderInvalidFacebookObjectPost doc if not doc.extra.message and not doc.extra.story
        return renderValidUrls statusTemplate { status: doc.extra.message or doc.extra.story }

    renderFacebookObjectPostPhoto = (doc) ->
        return renderInvalidFacebookObjectPost doc if not doc.picture
        return imgTemplate { source: doc.picture }

    ## Rendering TwitterObject document
    # Right now we only support TwitterObject with status type (aka tweets).

    renderTwitterObject = (doc) ->
        return renderInvalidTwitterObject doc if not doc.type

        switch doc.type
            when 'status' then return renderTwitterObjectStatus doc
            else renderInvalidTwitterObject doc

    renderInvalidTwitterObject = (doc) ->
        return renderInvalidObject doc.id, doc.model, doc.modelId, doc.type

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

    # We render twitter handles in tweets as links to Twitter users.

    twitterHandleRegex = /@(\w+)/ig

    renderTwitterHandles = (text) ->
        return text.replace twitterHandleRegex, '<a href="https://twitter.com/$1" target="_blank">@$1</a>'

    ## Rendering DropboxObject document

    renderDropboxObject = (doc) ->
        return renderInvalidObject doc.id, doc.model, doc.modelId, doc.type if not doc.path
        return imgTemplate { source: doc?.extra?.thumbnailUrl }

    ## Rendering EvernoteObject document

    renderEvernoteObject = (doc) ->
        return evernoteTemplate doc.extra

    ## Rendering SlackObject document

    renderSlackObject = (doc) ->
        return slackTemplate doc

    ## Rendering SlackObject document

    renderFoursquareObject = (doc) ->
        renderData =
            text:   doc?.text or ''
            venue:  doc.extra?.venue?.name or ''
        return foursquareTemplate renderData

    ## Return angularjs directive object

    return {
        restrict: 'E'
        scope: {
            event: '='
            lastYear: '='
            lastRow: '='
            lastItem: '='
        }
        link: link
    }
]
