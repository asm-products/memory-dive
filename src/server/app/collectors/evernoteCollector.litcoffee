
# Evernote collector module

This module is responsible for collection of user data from Evernote.

    debug       = (require 'debug') 'memdive::collectors::evernote'
    async       = require 'async'
    Evernote    = (require 'evernote').Evernote
    _           = require 'lodash'

## Initialization

Specialized error returned from Evernote calls.

    EvernoteError = (message) ->
        Error.call this
        @message = message
        return
    require('util').inherits EvernoteError, Error

During initialization we perform the standard operations for all the collectors: we capture the CompoundJS app context, add this module to its set of collectors and signal the rest of the app that the collector is ready.

    app = undefined

    exports.init = (compound) ->
        compound.on 'ready', (compoundApp) ->
            app = compoundApp

            app.collectors = app.collectors or {}
            app.collectors.evernote = exports
            app.emit 'evernoteCollectorReady'

## Exported functions

### `collectNotes`

This function will collect provider's associated Evernote data. It accepts three parameters:

1. `provider`: the user data provider object for which the data is being collected
2. `params`: optional params parameter with additional flags and options (`suppressThrottling` is the only one used)
3. `callback`: the callback function of (err, item, next) signature through which the method passes errors and items to the client. `next` is a function interator and should be invoked by the client when it has finished processing of the item (though not of error - in that case iteration shouldn't continue).

    exports.collectNotes = (provider, params, callback) ->

Since params is optional, it may be omitted by the clients in which case in its place we will have the callback function.

        if typeof params == 'function'
            callback = params
            params = {}

Ensure that we have enough data to attempt collection of the data. In this case we have no option but to throw.

        throw new EvernoteError('Invalid input params') if not provider or not params or not callback

        if not provider.providerId is app.common.constants.providerId.EVERNOTE or not provider.providerData or not provider.providerData.token
            return process.nextTick () ->
                return callback new EvernoteError('Provider not validly associated with Evernote')

        client = new Evernote.Client {
            token: provider.providerData.token
        }

        noteStore = client.getNoteStore()

        noteStore.listNotebooks (err, notebooks) ->
            return callback err if err

In order to avoid hitting Evernote's rate limits *and* to liberate the process to do other things while waiting on the collection of Evernote notes, we keep the list of pending notebooks and iterate over it, collecting each notebook separately. Furthermore, we request and process the notes in 10 notes batches (an arbitrary number though see below how we arrived at it).

            NOTE_BATCH_SIZE = 10

There are no concrete numbers from Evernote so the rate limit delay is just an educated guess (read: arbitrary number). For now, our algorithm is not efficient as it doesn't use webhooks and it checks the notes once a day. This could be improved by checking only the notes that have changed since the last collection.
The calculation of this value is goes something like this: if the max amount of notes that the user may have is 100,000 and we should be able to collect them in 24 hours (before another collection cycle kicks in), then that gives us a rate of just over 1 note per second. Including actual delays we shouldn't collect more than 80 notes in a minute. This translates into 8 batches where each batch should take 7.5 seconds. Assuming 2.5 seconds for retrieving and processing data the arbitrary delay is 5 seconds.
TODO: Improve this - use webhooks and other filtering techniques.

            EVERNOTE_RATE_LIMIT_AVOIDANCE_DELAY_IN_MILLISECONDS = 5000

            throttlingDelay = if params.suppressThrottling then 0 else EVERNOTE_RATE_LIMIT_AVOIDANCE_DELAY_IN_MILLISECONDS

            pendingNotebooks = notebooks

            readNextNotebook = () ->

                return callback() if _.isEmpty(pendingNotebooks)

                notebook = pendingNotebooks.pop()

                debug 'Collecting notebook', notebook.name

                currentOffset = 0

                readNextNotesBatch = () ->
                    debug ' > Reading notes from', currentOffset

                    noteFilter = new Evernote.NoteFilter
                    noteFilter.notebookGuid = notebook.guid

                    notesMetadataResultSpec = new Evernote.NotesMetadataResultSpec;
                    notesMetadataResultSpec.includeTitle = true
                    notesMetadataResultSpec.includeNotebookGuid = true

                    noteStore.findNotesMetadata client.token, noteFilter, currentOffset, NOTE_BATCH_SIZE, notesMetadataResultSpec, (error, notesMetadata) ->
                        return callback(error) if error
                        currentOffset = currentOffset + notesMetadata.notes.length

We asynchronously but serially iterate over all the items in the reply. The client invoked through callback is required to invoke next() for the next iteration to kick in.

                        async.eachSeries notesMetadata.notes, (note, next) ->
                            return next new EvernoteError 'Evernote note undefined' unless note

We retrieve each note in metadata. This has to be throttled.
TODO: Switch to webhooks.

                            # Oh jolly - let's put all those true/false, it's so easily understandable.
                            # Current config:
                            #   true: withContent
                            #   false: withResourcesData, withResourcesRecognition, withResourcesAlternateData
                            # Right now we are only interested in seeing the content.
                            noteStore.getNote client.token, note.guid, true, false, false, false, (error, noteData) ->
                                return callback error if error
                                return callback null, noteData, next

                        , (err) ->

When end of iteration comes, we check for error and continue reading new batches in the same notebook or we continue on to the next notebook.

                            return callback err if err

We throttle the collection of batches to avoid hitting the rate limits.

                            setTimeout () ->
                                return readNextNotesBatch() if !_.isEmpty(notesMetadata.notes)
                                readNextNotebook()
                            , throttlingDelay

We start the reading of notes by reading the next (first) batch of notes.

                readNextNotesBatch()

We start the reading of notebooks by reading the next (first) notebook.

            readNextNotebook()

### `collectUserData`

This function collects and returns user data associated with the provider's Evernote account.

    collectUserData = (provider, callback) ->

Ensure that we have enough data to attempt collection of the data. In this case we have no option but to throw.

        throw new EvernoteError('Invalid input params') if not provider or not callback

        if not provider.providerId is app.common.constants.providerId.EVERNOTE or not provider.providerData or not provider.providerData.token
            return process.nextTick () ->
                return callback new EvernoteError('Provider not validly associated with Evernote')

        client = new Evernote.Client {
            token: provider.providerData.token
        }

        userStore = client.getUserStore()

        userStore.getUser callback

    exports.collectUserData = collectUserData
